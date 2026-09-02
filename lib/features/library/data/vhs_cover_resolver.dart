import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vhsfin/features/library/data/ia_jsonp_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/library/data/ia_jsonp_web.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/tape.dart';

/// Real VHS sleeve art for a bookshelf spine (IA scan), when available.
class VhsSpineArt {
  const VhsSpineArt({
    required this.imageUrl,
    this.centerWidthFraction = 0.09,
  });

  final String imageUrl;

  /// Fraction of scan width to keep, centered. `1` = use the whole image
  /// (dedicated spine scan). Typical wraparound J-cards use ~0.09.
  final double centerWidthFraction;

  bool get isFullBleedSpine => centerWidthFraction >= 0.99;

  Map<String, dynamic> toJson() => {
        'u': imageUrl,
        'f': centerWidthFraction,
      };

  static VhsSpineArt? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final url = json['u'] as String?;
    if (url == null || url.isEmpty) return null;
    final f = (json['f'] as num?)?.toDouble() ?? 0.09;
    return VhsSpineArt(imageUrl: url, centerWidthFraction: f);
  }
}

/// Looks up period VHS sleeve scans (Internet Archive, then vhsplus.com.br).
///
/// Flutter web cannot `fetch` archive.org (no CORS) — we use JSONP instead.
/// vhsplus.com.br exposes a CORS-friendly WordPress REST API.
class VhsCoverResolver {
  VhsCoverResolver({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                headers: const {
                  'User-Agent': 'vhsfin/0.1 (kids jellyfin client)',
                },
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 12),
              ),
            );

  final Dio _dio;

  static const _cacheKey = 'vhsfin.ia_spine_art.v4';
  static const _miss = '__miss__';
  static const vhsEraLastYear = 2005;
  static const wraparoundSpineFraction = 0.09;
  static const missTtl = Duration(hours: 12);
  static const _vhsPlusApi = 'https://vhsplus.com.br/wp-json/wp/v2';

  /// English → Portuguese search hints for Brazilian VHS PLUS catalog.
  static const _ptHints = <String, List<String>>{
    'the lion king': ['o rei leao', 'rei leao'],
    'lion king': ['o rei leao', 'rei leao'],
    'beauty and the beast': ['a bela e a fera', 'bela e a fera'],
    'the little mermaid': ['a pequena sereia', 'pequena sereia'],
    'little mermaid': ['a pequena sereia', 'pequena sereia'],
    'lady and the tramp': ['a dama e o vagabundo', 'dama e o vagabundo'],
    '101 dalmatians': ['101 dalmatas', 'cento e um dalmatas'],
    'one hundred and one dalmatians': ['101 dalmatas'],
    'snow white': ['branca de neve'],
    'sleeping beauty': ['a bela adormecida', 'bela adormecida'],
    'cinderella': ['cinderela'],
    'peter pan': ['peter pan'],
    'pinocchio': ['pinocio', 'pinóquio'],
    'bambi': ['bambi'],
    'dumbo': ['dumbo'],
    'aladdin': ['aladdin', 'alladin'],
    'mulan': ['mulan'],
    'hercules': ['hercules', 'hércules'],
    'pocahontas': ['pocahontas'],
    'tarzan': ['tarzan'],
    'toy story': ['toy story'],
    'a bug\'s life': ['vida de inseto'],
    'monsters, inc': ['monstros s.a', 'monstros sa'],
    'finding nemo': ['procurando nemo'],
    'the incredibles': ['os incriveis', 'os incríveis'],
    'home alone': ['esqueca-me se for capaz', 'escondidos no sofá', 'home alone'],
  };

  final Map<String, String> _memory = {};

  Future<VhsSpineArt?> spineArtFor({
    required String title,
    int? year,
  }) async {
    if (year != null && year > vhsEraLastYear) {
      debugPrint('vhs-spine skip post-era "$title" ($year)');
      return null;
    }

    final key = _key(title, year);
    if (_memory.containsKey(key)) {
      return _decodeMemory(_memory[key]!);
    }

    final prefs = await SharedPreferences.getInstance();
    final disk = _readDisk(prefs);
    if (disk.containsKey(key)) {
      final value = disk[key]!;
      if (_isFreshMiss(value) || !_isMiss(value)) {
        _memory[key] = value;
        return _decodeMemory(value);
      }
      disk.remove(key);
    }

    final resolved = await _search(title, year);
    final stored = resolved == null
        ? jsonEncode({
            'miss': true,
            'at': DateTime.now().toUtc().toIso8601String(),
          })
        : jsonEncode(resolved.toJson());
    _memory[key] = stored;
    disk[key] = stored;
    await prefs.setString(_cacheKey, jsonEncode(disk));
    debugPrint(
      resolved == null
          ? 'vhs-spine MISS "$title" ($year)'
          : 'vhs-spine HIT "$title" → ${resolved.imageUrl}',
    );
    return resolved;
  }

  Future<String?> coverUrlFor({
    required String title,
    int? year,
  }) async {
    return (await spineArtFor(title: title, year: year))?.imageUrl;
  }

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
      return DateTime.now().toUtc().difference(at) < missTtl;
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

  Future<VhsSpineArt?> _search(String title, int? year) async {
    final cleaned = _normalizeTitle(title);
    if (cleaned.isEmpty) return null;

    final fromIa = await _searchInternetArchive(cleaned, year);
    if (fromIa != null) return fromIa;

    final fromPlus = await _searchVhsPlus(cleaned);
    if (fromPlus != null) return fromPlus;

    return null;
  }

  Future<VhsSpineArt?> _searchInternetArchive(
    String cleaned,
    int? year,
  ) async {
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

  Future<VhsSpineArt?> _searchVhsPlus(String cleaned) async {
    final terms = <String>{
      cleaned,
      cleaned.replaceFirst(RegExp(r'^(the|a|an)\s+', caseSensitive: false), ''),
      ...?_ptHints[cleaned.toLowerCase()],
    };

    final ranked = <({Map<String, dynamic> post, double score})>[];
    for (final term in terms) {
      if (term.trim().isEmpty) continue;
      try {
        final response = await _dio.get<List<dynamic>>(
          '$_vhsPlusApi/posts',
          queryParameters: {
            'search': term,
            'per_page': 8,
            '_embed': '1',
          },
        );
        final posts = response.data ?? const [];
        for (final raw in posts) {
          if (raw is! Map<String, dynamic>) continue;
          final slug = (raw['slug'] as String? ?? '').toLowerCase();
          final titleHtml = raw['title'];
          final title = titleHtml is Map
              ? (titleHtml['rendered'] as String? ?? '')
              : '$titleHtml';
          final plain = _stripHtml(title).toLowerCase();
          if (_looksLikeVhsPlusShop(slug, plain)) continue;
          final score = _vhsPlusScore(
            slug: slug,
            title: plain,
            wanted: cleaned.toLowerCase(),
            term: term.toLowerCase(),
          );
          if (score < 0.4) continue;
          ranked.add((post: raw, score: score));
        }
      } catch (err) {
        debugPrint('vhs-spine vhsplus error for "$term": $err');
      }
    }

    if (ranked.isEmpty) return null;
    ranked.sort((a, b) => b.score.compareTo(a.score));

    for (final hit in ranked.take(5)) {
      final url = await _vhsPlusImageUrl(hit.post);
      if (url == null) continue;
      final titleMap = hit.post['title'];
      final label = titleMap is Map
          ? _stripHtml(titleMap['rendered'] as String? ?? '')
          : _stripHtml('$titleMap');
      debugPrint('vhs-spine vhsplus hit "$label" → $url');
      return VhsSpineArt(
        imageUrl: url,
        centerWidthFraction: wraparoundSpineFraction,
      );
    }
    return null;
  }

  Future<String?> _vhsPlusImageUrl(Map<String, dynamic> post) async {
    final embedded = post['_embedded'];
    if (embedded is Map) {
      final media = embedded['wp:featuredmedia'];
      if (media is List && media.isNotEmpty && media.first is Map) {
        final full = media.first['source_url'] as String?;
        if (full != null && full.isNotEmpty) return full;
      }
    }

    final mediaId = post['featured_media'];
    if (mediaId is! int || mediaId <= 0) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_vhsPlusApi/media/$mediaId',
      );
      final url = response.data?['source_url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    } catch (err) {
      debugPrint('vhs-spine vhsplus media error: $err');
    }
    return null;
  }

  bool _looksLikeVhsPlusShop(String slug, String title) {
    const bad = [
      'loja',
      'lojavhsplus',
      'catalogo-de-filmes',
      'mercado',
      'pirataria',
      'wishlist',
    ];
    for (final token in bad) {
      if (slug.contains(token) || title.contains(token)) return true;
    }
    return false;
  }

  double _vhsPlusScore({
    required String slug,
    required String title,
    required String wanted,
    required String term,
  }) {
    var score = _score('$title $slug', wanted);
    if (title.contains(term) || slug.contains(term.replaceAll(' ', '-'))) {
      score += 0.2;
    }
    if (slug.contains('capa') ||
        slug.contains('capavhs') ||
        slug.endsWith('-vhs') ||
        title.contains('capa')) {
      score += 0.25;
    }
    // Prefer dedicated cover posts over blog noise.
    if (slug == wanted.replaceAll(' ', '-') ||
        slug == term.replaceAll(' ', '-')) {
      score += 0.2;
    }
    return score.clamp(0.0, 1.0);
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&#8211;', '-')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Future<List<Map<String, dynamic>>> _searchDocs(String query) async {
    if (kIsWeb) {
      final multiFl = 'https://archive.org/advancedsearch.php'
          '?q=${Uri.encodeQueryComponent(query)}'
          '&fl[]=identifier&fl[]=title&fl[]=year&fl[]=mediatype'
          '&rows=8&output=json';
      final data = await iaJsonp(multiFl);
      final docs =
          data['response']?['docs'] as List<dynamic>? ?? const [];
      return docs.cast<Map<String, dynamic>>();
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
    final docs =
        response.data?['response']?['docs'] as List<dynamic>? ?? const [];
    return docs.cast<Map<String, dynamic>>();
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
      return VhsSpineArt(
        imageUrl: 'https://archive.org/services/img/$id',
        centerWidthFraction: wraparoundSpineFraction,
      );
    }
  }

  ({String name, int size})? _pickScanFile(List<dynamic> files) {
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
      final isImage = format.contains('jpeg') ||
          format.contains('jpg') ||
          format.contains('png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png');
      if (!isImage) continue;
      final size = int.tryParse('${file['size']}') ?? 0;
      final candidate = (name: name, size: size);
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
      'recorded',
      'episode',
      'ytp',
      'audio',
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
    final wantedParts =
        asciiWanted.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
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

  String _key(String title, int? year) =>
      '${_normalizeTitle(title).toLowerCase()}|${year ?? ''}';

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

final vhsCoverResolverProvider = Provider<VhsCoverResolver>((ref) {
  return VhsCoverResolver();
});

/// Resolves spine art for a tape: Jellyfin Box image first, else remote lookup.
/// New hits may be saved as Jellyfin `Box` — never overwrites an existing Box.
final vhsSpineArtProvider =
    FutureProvider.family<VhsSpineArt?, Tape>((ref, tape) async {
  if (tape.hasBoxImage) {
    return VhsSpineArt(
      imageUrl: tape.boxImageUrl!,
      centerWidthFraction: VhsCoverResolver.wraparoundSpineFraction,
    );
  }

  final art = await ref.watch(vhsCoverResolverProvider).spineArtFor(
        title: tape.title,
        year: tape.productionYear,
      );
  if (art == null || tape.isDemo) return art;

  final session = ref.watch(sessionProvider);
  if (session == null) return art;

  final client = ref.watch(jellyfinClientProvider);
  // saveBoxImageFromUrl also re-checks ImageTags and refuses overwrite.
  final saved = await client.saveBoxImageFromUrl(
    session: session,
    itemId: tape.id,
    imageUrl: art.imageUrl,
  );
  if (saved) {
    debugPrint('vhs-spine saved Box to Jellyfin for "${tape.title}"');
    return VhsSpineArt(
      imageUrl: '${session.normalizedServerUrl}/Items/${tape.id}/Images/Box'
          '?maxHeight=1200&quality=90&api_key=${session.accessToken}',
      centerWidthFraction: art.centerWidthFraction,
    );
  }
  return art;
});
