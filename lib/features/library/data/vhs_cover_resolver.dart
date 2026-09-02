import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vhsfin/features/library/data/ia_jsonp_stub.dart'
    if (dart.library.js_interop) 'package:vhsfin/features/library/data/ia_jsonp_web.dart';

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

/// Looks up period VHS sleeve scans on Internet Archive and caches hits.
///
/// Flutter web cannot `fetch` archive.org (no CORS) — we use JSONP instead.
/// VHSCollector.com has no API and is mid-rebuild — not used.
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

  static const _cacheKey = 'vhsfin.ia_spine_art.v3';
  static const _miss = '__miss__';
  static const vhsEraLastYear = 2005;
  static const wraparoundSpineFraction = 0.09;
  static const missTtl = Duration(hours: 12);

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
        debugPrint('vhs-spine query docs=${docs.length} for "$cleaned"');
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
        debugPrint('vhs-spine search error: $err');
      }
    }
    return null;
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
    if (docTitle.contains(wanted)) score += 0.55;
    final wantedParts =
        wanted.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (wantedParts.isNotEmpty) {
      var hits = 0;
      for (final part in wantedParts) {
        if (docTitle.contains(part)) hits++;
      }
      score += 0.35 * (hits / wantedParts.length);
    }
    if (docTitle.contains('vhs cover') || docTitle.contains('case cover')) {
      score += 0.25;
    } else if (docTitle.contains('cover') || docTitle.contains('sleeve')) {
      score += 0.1;
    }
    if (docTitle.contains('spine')) score += 0.15;
    return score.clamp(0.0, 1.0);
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

final vhsSpineArtProvider =
    FutureProvider.family<VhsSpineArt?, ({String title, int? year})>(
        (ref, args) {
  return ref.watch(vhsCoverResolverProvider).spineArtFor(
        title: args.title,
        year: args.year,
      );
});
