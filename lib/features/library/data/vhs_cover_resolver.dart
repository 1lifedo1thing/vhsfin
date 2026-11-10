import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vhsfin/constants/build_flags.dart';

import 'package:vhsfin/features/library/data/ia_jsonp_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/library/data/ia_jsonp_web.dart';
import 'package:vhsfin/features/library/model/tape.dart';

/// Real VHS sleeve art for a bookshelf spine (and optional front cover).
class VhsSpineArt {
  const VhsSpineArt({
    required this.imageUrl,
    this.centerWidthFraction = 0.09,
    this.frontImageUrl,
  });

  /// Spine source — dedicated spine scan, or a flat wraparound sleeve.
  final String imageUrl;

  /// Fraction of [imageUrl] width to keep, centered. `1` = whole image
  /// (dedicated spine). Typical wraparound J-cards use ~0.09.
  final double centerWidthFraction;

  /// Dedicated front cover when available (VHSCollector `imgfront`).
  final String? frontImageUrl;

  bool get isFullBleedSpine => centerWidthFraction >= 0.99;

  /// Wraparound sleeve — front is the right panel when [frontImageUrl] is null.
  bool get isWraparound => centerWidthFraction < 0.99;

  Map<String, dynamic> toJson() => {
    'u': imageUrl,
    'f': centerWidthFraction,
    if (frontImageUrl != null) 'front': frontImageUrl,
  };

  static VhsSpineArt? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final url = json['u'] as String?;
    if (url == null || url.isEmpty) return null;
    final f = (json['f'] as num?)?.toDouble() ?? 0.09;
    final front = json['front'] as String?;
    return VhsSpineArt(
      imageUrl: url,
      centerWidthFraction: f,
      frontImageUrl: front,
    );
  }
}

/// Looks up period VHS sleeve scans (VHSCollector, then Internet Archive).
///
/// VHSCollector is compiled in only with [vhsCollectorBuild], then opt-in
/// ([useCollector], off by default); Internet Archive
/// is always tried. Cache keys are namespaced per mode so turning VHSCollector
/// on retries titles that missed on IA alone. VHSCollector uses predictable `/movie/{slug}` pages with dedicated spine
/// or wraparound sleeve scans. Flutter web hits them via `/vc/lookup` proxy
/// (no CORS on vhscollector.com). IA still uses JSONP on web.
class VhsCoverResolver {
  VhsCoverResolver({Dio? dio, this.useCollector = false})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              headers: const {
                'User-Agent': 'VHSFin/1.0 (+https://vhsfin.markdid.dev)',
              },
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 12),
            ),
          );

  final Dio _dio;

  /// Also search vhscollector.com before Internet Archive.
  final bool useCollector;

  static const _cacheKey = 'vhsfin.spine_art.v11';
  static const _miss = '__miss__';
  static const vhsEraLastYear = 2005;
  static const wraparoundSpineFraction = 0.09;

  /// Keep ordinary misses around long enough that relaunch / VHS-only warm
  /// does not re-stampede VHSCollector + IA (timeouts stack up on phones).
  static const missTtl = Duration(days: 14);
  static const _collectorBase = 'https://vhscollector.com';

  final Map<String, String> _memory = {};
  Map<String, String>? _disk;
  Future<void>? _diskLoad;

  /// Episodes remap to one `"Show Season N"` lookup so we don't stampede
  /// VHSCollector / IA opening a long season. Year is cleared so every
  /// episode in the season shares the cache entry.
  static ({String title, int? year, String? seriesTitle, TapeKind kind})
  lookupIdentity({
    required String title,
    int? year,
    String? seriesTitle,
    int? seasonNumber,
    TapeKind kind = TapeKind.movie,
  }) {
    if (kind == TapeKind.episode) {
      final show = seriesTitle?.trim();
      if (show != null && show.isNotEmpty) {
        if (seasonNumber != null) {
          return (
            title: 'Season $seasonNumber',
            year: null,
            seriesTitle: show,
            kind: TapeKind.series,
          );
        }
        return (
          title: show,
          year: null,
          seriesTitle: null,
          kind: TapeKind.series,
        );
      }
    }
    return (title: title, year: year, seriesTitle: seriesTitle, kind: kind);
  }

  Future<VhsSpineArt?> spineArtFor({
    required String title,
    int? year,
    String? seriesTitle,
    int? seasonNumber,
    TapeKind kind = TapeKind.movie,
    bool allowNetwork = true,
  }) async {
    final id = lookupIdentity(
      title: title,
      year: year,
      seriesTitle: seriesTitle,
      seasonNumber: seasonNumber,
      kind: kind,
    );
    title = id.title;
    year = id.year;
    seriesTitle = id.seriesTitle;
    kind = id.kind;

    // Movies past the VHS era are skipped; series still try — retail TV
    // box sets often post-date 2005 airings.
    final relaxYear = kind == TapeKind.episode || kind == TapeKind.series;
    if (!relaxYear && year != null && year > vhsEraLastYear) {
      debugPrint('vhs-spine skip post-era "$title" ($year)');
      return null;
    }

    final key = _key(title, year, seriesTitle, kind);
    if (_memory.containsKey(key)) {
      return _decodeMemory(_memory[key]!);
    }

    final disk = await _ensureDisk();
    if (disk.containsKey(key)) {
      final value = disk[key]!;
      // Hits always win. Fresh misses win. Stale misses are reused when we are
      // not allowed to hit the network (warm / relaunch), so phones don't
      // re-timeout hundreds of known-empty titles.
      if (!_isMiss(value) || _isFreshMiss(value) || !allowNetwork) {
        _memory[key] = value;
        return _decodeMemory(value);
      }
      disk.remove(key);
    }

    if (!allowNetwork) return null;

    final resolved = await _search(
      title,
      year: year,
      seriesTitle: seriesTitle,
      kind: kind,
      relaxYear: relaxYear,
    );
    final stored = resolved == null
        ? jsonEncode({
            'miss': true,
            'at': DateTime.now().toUtc().toIso8601String(),
          })
        : jsonEncode(resolved.toJson());
    _memory[key] = stored;
    disk[key] = stored;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(disk));
    debugPrint(
      resolved == null
          ? 'vhs-spine MISS "$title" ($year) kind=$kind'
          : 'vhs-spine HIT "$title" kind=$kind → ${resolved.imageUrl}',
    );
    return resolved;
  }

  /// Whether this title identity already has a disk/memory cache entry
  /// (hit or miss). Used by art warm to skip network for known titles.
  Future<bool> hasCachedLookup({
    required String title,
    int? year,
    String? seriesTitle,
    int? seasonNumber,
    TapeKind kind = TapeKind.movie,
  }) async {
    final id = lookupIdentity(
      title: title,
      year: year,
      seriesTitle: seriesTitle,
      seasonNumber: seasonNumber,
      kind: kind,
    );
    final key = _key(id.title, id.year, id.seriesTitle, id.kind);
    if (_memory.containsKey(key)) return true;
    final disk = await _ensureDisk();
    return disk.containsKey(key);
  }

  Future<String?> coverUrlFor({
    required String title,
    int? year,
    String? seriesTitle,
    int? seasonNumber,
    TapeKind kind = TapeKind.movie,
  }) async {
    return (await spineArtFor(
      title: title,
      year: year,
      seriesTitle: seriesTitle,
      seasonNumber: seasonNumber,
      kind: kind,
    ))?.imageUrl;
  }

  /// Permanently treat this title key as a miss so a rejected sleeve is not
  /// re-fetched from VHSCollector / IA (miss TTL still refreshes eventually).
  Future<void> forceMiss({
    required String title,
    int? year,
    String? seriesTitle,
    int? seasonNumber,
    TapeKind kind = TapeKind.movie,
  }) async {
    final id = lookupIdentity(
      title: title,
      year: year,
      seriesTitle: seriesTitle,
      seasonNumber: seasonNumber,
      kind: kind,
    );
    final key = _key(id.title, id.year, id.seriesTitle, id.kind);
    final stored = jsonEncode({
      'miss': true,
      'at': DateTime.now().toUtc().toIso8601String(),
      'rejected': true,
    });
    _memory[key] = stored;
    final disk = await _ensureDisk();
    disk[key] = stored;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(disk));
    debugPrint(
      'vhs-spine REJECT → miss "${id.title}" (${id.year}) kind=${id.kind}',
    );
  }

  Future<Map<String, String>> _ensureDisk() async {
    if (_disk != null) return _disk!;
    _diskLoad ??= () async {
      final prefs = await SharedPreferences.getInstance();
      _disk = _readDisk(prefs);
    }();
    await _diskLoad;
    return _disk!;
  }

  /// Rejected sleeves stay missed longer than ordinary cache misses.
  static const rejectedMissTtl = Duration(days: 365);

  bool _isMiss(String raw) {
    if (raw == _miss) return true;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['miss'] == true;
    } catch (_) {
      return false;
    }
  }

  bool _isFreshMiss(String raw) {
    if (raw == _miss) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['miss'] != true) return false;
      final at = DateTime.tryParse(map['at'] as String? ?? '');
      if (at == null) return false;
      final ttl = map['rejected'] == true ? rejectedMissTtl : missTtl;
      return DateTime.now().toUtc().difference(at) < ttl;
    } catch (_) {
      return false;
    }
  }

  VhsSpineArt? _decodeMemory(String raw) {
    if (_isMiss(raw)) return null;
    try {
      return VhsSpineArt.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String _normalizeTitle(String title) {
    var t = title.trim();
    t = t.replaceAll(RegExp(r'\s*\(\d{4}\)\s*$'), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    final article = RegExp(
      r'^(.+),\s*(The|A|An)$',
      caseSensitive: false,
    ).firstMatch(t);
    if (article != null) {
      t = '${article.group(2)} ${article.group(1)}';
    }
    return t.trim();
  }

  Future<VhsSpineArt?> _search(
    String title, {
    int? year,
    String? seriesTitle,
    TapeKind kind = TapeKind.movie,
    bool relaxYear = false,
  }) async {
    final cleaned = _normalizeTitle(title);
    if (cleaned.isEmpty) return null;

    final series = seriesTitle == null ? null : _normalizeTitle(seriesTitle);
    // Prefer "Show Season N" before bare "Season N" (ambiguous / wasteful).
    final lookupTitles = <String>{
      if (series != null && series.isNotEmpty) ...[
        '$series $cleaned',
        '$series - $cleaned',
        '$series: $cleaned',
      ],
      cleaned,
    };
    // "Show - Episode Title" → also try the bare episode name.
    if (series != null &&
        cleaned.toLowerCase().startsWith(series.toLowerCase())) {
      final bare = cleaned
          .substring(series.length)
          .replaceFirst(RegExp(r'^[\s:\-–—]+'), '')
          .trim();
      if (bare.isNotEmpty) lookupTitles.add(bare);
    }

    final isSeriesBox = kind == TapeKind.series;
    if (vhsCollectorBuild && useCollector) {
      for (final queryTitle in lookupTitles) {
        final fromCollector = await _searchVhsCollector(
          queryTitle,
          avoidAmbiguousMovieSlug: isSeriesBox,
        );
        if (fromCollector != null) return fromCollector;
      }
    }

    // IA is weaker for episode tapes; still try primary title.
    final iaYear = (!relaxYear || (year != null && year <= vhsEraLastYear))
        ? year
        : null;
    final iaPrimary = isSeriesBox ? '$cleaned TV' : cleaned;
    final fromIa = await _searchInternetArchive(iaPrimary, iaYear);
    if (fromIa != null) return fromIa;

    if (series != null && series.isNotEmpty) {
      final fromIaSeries = await _searchInternetArchive(
        '$series $cleaned',
        iaYear,
      );
      if (fromIaSeries != null) return fromIaSeries;
    }

    return null;
  }

  /// Short generic titles collide with same-named films on VHSCollector.
  bool _ambiguousCollectorTitle(String cleaned) {
    final words = cleaned
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 3) return false;
    final compact = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return compact.length <= 14;
  }

  Future<VhsSpineArt?> _searchInternetArchive(String cleaned, int? year) async {
    final softYear = year != null
        ? ' AND year:[${year - 1} TO ${year + 10}]'
        : ' AND year:[1975 TO $vhsEraLastYear]';

    final queries = <String>[
      'title:("$cleaned") AND (title:("vhs cover") OR title:("VHS Cover") OR title:("vhs case") OR title:("Case Cover"))',
      'title:("$cleaned") AND (title:("vhs cover") OR title:("VHS Cover"))$softYear',
      'title:("$cleaned") AND subject:(vhs) AND (cover OR sleeve OR scan) AND mediatype:image',
      '("$cleaned") AND ("vhs cover" OR "VHS Cover" OR "vhs case cover") AND mediatype:image',
    ];

    for (final query in queries) {
      try {
        final docs = await _searchDocs(query);
        debugPrint('vhs-spine IA docs=${docs.length} for "$cleaned"');
        final ranked = <({Map<String, dynamic> doc, double score})>[];
        for (final doc in docs) {
          final id = doc['identifier'] as String?;
          if (id == null || id.isEmpty) continue;
          final docTitle = (doc['title'] as String? ?? '').toLowerCase();
          if (_looksLikeVideoRip(docTitle)) continue;
          final score = _score(docTitle, cleaned.toLowerCase());
          if (score < 0.35) continue;
          ranked.add((doc: doc, score: score));
        }
        ranked.sort((a, b) => b.score.compareTo(a.score));
        for (final hit in ranked) {
          final id = hit.doc['identifier'] as String;
          final art = await _artFromIdentifier(id, hit.doc);
          if (art != null) return art;
        }
      } catch (err) {
        debugPrint('vhs-spine IA search error: $err');
      }
    }
    return null;
  }

  Future<VhsSpineArt?> _searchVhsCollector(
    String cleaned, {
    bool avoidAmbiguousMovieSlug = false,
  }) async {
    try {
      final queries = <String>[
        if (avoidAmbiguousMovieSlug) ...[
          '$cleaned TV',
          '$cleaned series',
          // Only use the bare title when it's specific enough.
          if (!_ambiguousCollectorTitle(cleaned)) cleaned,
        ] else
          cleaned,
      ];

      for (final query in queries) {
        if (kIsWeb) {
          final response = await _dio.get<Map<String, dynamic>>(
            '/vc/lookup',
            queryParameters: {'title': query},
            options: Options(
              validateStatus: (code) => code != null && code < 500,
            ),
          );
          final data = response.data;
          if (data == null || data['ok'] != true) continue;
          final url = data['imageUrl'] as String?;
          if (url == null || url.isEmpty) continue;
          final fraction =
              (data['fraction'] as num?)?.toDouble() ?? wraparoundSpineFraction;
          final front = data['frontImageUrl'] as String?;
          debugPrint(
            'vhs-spine collector HIT "${data['slug']}" (${data['kind']}) → $url',
          );
          return VhsSpineArt(
            imageUrl: url,
            centerWidthFraction: fraction,
            frontImageUrl: front,
          );
        }

        for (final slug in _collectorSlugs(query)) {
          final art = await _collectorArtFromSlug(slug);
          if (art != null) return art;
        }
      }
    } catch (err) {
      debugPrint('vhs-spine collector error: $err');
    }
    return null;
  }

  List<String> _collectorSlugs(String cleaned) {
    final base = cleaned
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll('’', '')
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) return const [];
    final bare = base.replaceFirst(RegExp(r'^(the|a|an)-'), '');
    final collapsed = base.replaceAll('-and-', '-');
    return {
      base,
      if (bare.isNotEmpty && bare != base) bare,
      if (collapsed != base) collapsed,
    }.toList();
  }

  Future<VhsSpineArt?> _collectorArtFromSlug(String slug) async {
    try {
      final response = await _dio.get<String>(
        '$_collectorBase/movie/$slug',
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      if (response.statusCode != 200 || response.data == null) return null;
      return _parseCollectorHtml(response.data!);
    } catch (err) {
      debugPrint('vhs-spine collector slug=$slug: $err');
      return null;
    }
  }

  VhsSpineArt? _parseCollectorHtml(String html) {
    String? fieldUrl(String field) {
      final idx = html.indexOf(field);
      if (idx < 0) return null;
      final chunk = html.substring(idx, (idx + 2500).clamp(0, html.length));
      final matches = RegExp(
        r"""(?:https://vhscollector\.com)?(/sites/default/files/vhsimages/[^"'>\s]+\.jpg)""",
        caseSensitive: false,
      ).allMatches(chunk);
      for (final match in matches) {
        final path = match.group(1)!;
        if (path.contains('/styles/')) continue;
        return path.startsWith('http') ? path : '$_collectorBase$path';
      }
      return null;
    }

    final front = fieldUrl('field--name-field-vhs-imgfront');
    final spine = fieldUrl('field--name-field-vhs-imgspine');
    final comb = fieldUrl('field--name-field-vhs-imgcomb');
    if (spine != null) {
      return VhsSpineArt(
        imageUrl: spine,
        centerWidthFraction: 1,
        frontImageUrl: front,
      );
    }
    if (comb != null) {
      return VhsSpineArt(imageUrl: comb, frontImageUrl: front);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _searchDocs(String query) async {
    if (kIsWeb) {
      final multiFl =
          'https://archive.org/advancedsearch.php'
          '?q=${Uri.encodeQueryComponent(query)}'
          '&fl[]=identifier&fl[]=title&fl[]=year&fl[]=mediatype'
          '&rows=8&output=json';
      return _docsOf(await iaJsonp(multiFl));
    }

    final response = await _dio.get<Map<String, dynamic>>(
      'https://archive.org/advancedsearch.php',
      queryParameters: {
        'q': query,
        'fl[]': ['identifier', 'title', 'year', 'mediatype'],
        'rows': 8,
        'output': 'json',
      },
    );
    return _docsOf(response.data);
  }

  /// `response.docs` from an Internet Archive search, skipping anything
  /// that isn't shaped like a result (an unexpected reply means no results).
  static List<Map<String, dynamic>> _docsOf(Object? data) {
    if (data is! Map) return const [];
    final response = data['response'];
    if (response is! Map) return const [];
    final docs = response['docs'];
    if (docs is! List) return const [];
    return docs.whereType<Map<String, dynamic>>().toList();
  }

  Future<VhsSpineArt?> _artFromIdentifier(
    String id,
    Map<String, dynamic> doc,
  ) async {
    try {
      final Map<String, dynamic> meta;
      if (kIsWeb) {
        meta = await iaJsonp('https://archive.org/metadata/$id');
      } else {
        final response = await _dio.get<Map<String, dynamic>>(
          'https://archive.org/metadata/$id',
        );
        meta = response.data ?? {};
      }
      final files = meta['files'] as List<dynamic>? ?? const [];
      final pick = _pickScanFile(files);
      if (pick == null) return null;
      final name = pick.name;
      final url =
          'https://archive.org/download/$id/${Uri.encodeComponent(name)}';
      final title = (doc['title'] as String? ?? name).toLowerCase();
      final fraction = _spineFractionFor(name: name, title: title);
      return VhsSpineArt(imageUrl: url, centerWidthFraction: fraction);
    } catch (err) {
      debugPrint('vhs-spine metadata error id=$id: $err');
      return VhsSpineArt(imageUrl: 'https://archive.org/services/img/$id');
    }
  }

  ({String name, int size})? _pickScanFile(List<dynamic> files) {
    final images = <({String name, int size})>[];
    final pick = _pickLargestScan(files, images);
    if (pick == null) return null;
    // Uploaders often add the same scan at several resolutions/formats
    // ("9. cover out 600.png" 63 MB, "15. cover out 300.jpg" 3 MB). The
    // largest picks the scan; fetch its smallest copy that's still sharp.
    final stem = scanStem(pick.name);
    final copies =
        images
            .where((f) => scanStem(f.name) == stem && f.size >= minScanBytes)
            .toList()
          ..sort((a, b) => a.size.compareTo(b.size));
    final chosen = copies.isEmpty ? pick : copies.first;
    // A 200 MB master is never worth a phone download: try the next match.
    return chosen.size > maxScanBytes ? null : chosen;
  }

  /// Copies smaller than this are previews, not scans.
  static const minScanBytes = 1000000;
  static const maxScanBytes = 50000000;

  /// "9. cover out 600.png" → "cover out": drops the upload index, dpi, size
  /// word, and extension so renditions of one scan compare equal.
  @visibleForTesting
  static String scanStem(String name) => name
      .toLowerCase()
      .replaceFirst(RegExp(r'\.[a-z0-9]+$'), '')
      .replaceFirst(RegExp(r'^\d+[.\s_-]+'), '')
      .replaceFirst(
        RegExp(r'[\s_-]*(72|96|150|200|300|400|600|1200)\s*(dpi)?$'),
        '',
      )
      .replaceFirst(
        RegExp(r'[\s_-]*(small|medium|large|big|full|hi-?res|low-?res)$'),
        '',
      )
      .trim();

  ({String name, int size})? _pickLargestScan(
    List<dynamic> files,
    List<({String name, int size})> images,
  ) {
    ({String name, int size})? best;
    ({String name, int size})? spineNamed;

    for (final raw in files) {
      final file = raw as Map<String, dynamic>;
      final name = file['name'] as String? ?? '';
      final source = file['source'] as String? ?? '';
      final format = (file['format'] as String? ?? '').toLowerCase();
      final lower = name.toLowerCase();
      if (source == 'metadata') continue;
      if (lower.contains('_thumb') || lower.startsWith('__ia_thumb')) continue;
      final isImage =
          format.contains('jpeg') ||
          format.contains('jpg') ||
          format.contains('png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png');
      if (!isImage) continue;
      final size = int.tryParse('${file['size']}') ?? 0;
      final candidate = (name: name, size: size);
      images.add(candidate);
      if (lower.contains('spine')) {
        if (spineNamed == null || size > spineNamed.size) {
          spineNamed = candidate;
        }
      }
      if (best == null || size > best.size) {
        best = candidate;
      }
    }
    return spineNamed ?? best;
  }

  double _spineFractionFor({required String name, required String title}) {
    final blob = '$name $title'.toLowerCase();
    if (blob.contains('spine') && !blob.contains('cover')) {
      return 1;
    }
    return wraparoundSpineFraction;
  }

  bool _looksLikeVideoRip(String docTitle) {
    const bad = [
      'opening to',
      'closing to',
      'full vhs',
      'vhs rip',
      'complete vhs',
      'recorded from',
      'ytp',
      'audio only',
    ];
    for (final token in bad) {
      if (docTitle.contains(token)) return true;
    }
    return false;
  }

  double _score(String docTitle, String wanted) {
    var score = 0.0;
    final asciiWanted = _fold(wanted);
    final asciiDoc = _fold(docTitle);
    if (asciiDoc.contains(asciiWanted)) score += 0.55;
    final wantedParts = asciiWanted
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
    if (wantedParts.isNotEmpty) {
      var hits = 0;
      for (final part in wantedParts) {
        if (asciiDoc.contains(part)) hits++;
      }
      score += 0.35 * (hits / wantedParts.length);
    }
    if (asciiDoc.contains('vhs cover') || asciiDoc.contains('case cover')) {
      score += 0.25;
    } else if (asciiDoc.contains('cover') ||
        asciiDoc.contains('sleeve') ||
        asciiDoc.contains('capa')) {
      score += 0.1;
    }
    if (asciiDoc.contains('spine')) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _key(
    String title,
    int? year, [
    String? seriesTitle,
    TapeKind kind = TapeKind.movie,
  ]) =>
      '${useCollector ? 'vc|' : ''}${_normalizeTitle(title).toLowerCase()}|${seriesTitle?.toLowerCase() ?? ''}|${year ?? ''}|${kind.name}';

  Map<String, String> _readDisk(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, '$v'));
    } catch (_) {
      return {};
    }
  }
}
