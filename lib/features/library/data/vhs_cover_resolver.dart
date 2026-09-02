import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Only searches titles from ~2005 and earlier (VHS era). Hits are meant to be
/// shown as the whole spine via a centered vertical crop — no procedural text.
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
  static const _cacheKey = 'vhsfin.ia_spine_art.v2';
  static const _miss = '__miss__';
  static const vhsEraLastYear = 2005;

  /// Center strip of a flat BACK|SPINE|FRONT J-card.
  static const wraparoundSpineFraction = 0.09;

  final Map<String, String> _memory = {};

  Future<VhsSpineArt?> spineArtFor({
    required String title,
    int? year,
  }) async {
    if (year != null && year > vhsEraLastYear) return null;

    final key = _key(title, year);
    if (_memory.containsKey(key)) {
      return _decodeMemory(_memory[key]!);
    }

    final prefs = await SharedPreferences.getInstance();
    final disk = _readDisk(prefs);
    if (disk.containsKey(key)) {
      final value = disk[key]!;
      _memory[key] = value;
      return _decodeMemory(value);
    }

    final resolved = await _search(title, year);
    final stored = resolved == null ? _miss : jsonEncode(resolved.toJson());
    _memory[key] = stored;
    disk[key] = stored;
    await prefs.setString(_cacheKey, jsonEncode(disk));
    return resolved;
  }

  /// Legacy helper — image URL only.
  Future<String?> coverUrlFor({
    required String title,
    int? year,
  }) async {
    return (await spineArtFor(title: title, year: year))?.imageUrl;
  }

  VhsSpineArt? _decodeMemory(String raw) {
    if (raw == _miss) return null;
    try {
      return VhsSpineArt.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<VhsSpineArt?> _search(String title, int? year) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return null;

    final yearClause = year != null ? ' AND year:[$year TO $year]' : '';
    final eraClause = ' AND year:[1975 TO $vhsEraLastYear]';

    final queries = <String>[
      'title:("$cleaned") AND (title:("vhs cover") OR title:("VHS Cover") OR title:("vhs case"))$yearClause',
      'title:("$cleaned") AND subject:(vhs) AND (cover OR sleeve OR scan) AND mediatype:image$eraClause',
      'title:("$cleaned") AND (title:("vhs cover") OR title:("VHS Cover"))$eraClause',
      'title:("$cleaned") AND (vhs OR videocassette) AND mediatype:image$eraClause',
    ];

    for (final query in queries) {
      try {
        final url =
            'https://archive.org/advancedsearch.php'
            '?q=${Uri.encodeQueryComponent(query)}'
            '&fl[]=identifier&fl[]=title&fl[]=year&fl[]=mediatype'
            '&rows=8&output=json';
        final response = await _dio.get<Map<String, dynamic>>(url);
        final docs =
            response.data?['response']?['docs'] as List<dynamic>? ?? const [];
        final ranked = <({Map<String, dynamic> doc, double score})>[];
        for (final raw in docs) {
          final doc = raw as Map<String, dynamic>;
          final id = doc['identifier'] as String?;
          if (id == null || id.isEmpty) continue;
          final docTitle = (doc['title'] as String? ?? '').toLowerCase();
          // Skip obvious tape rips / openings, keep cover scans.
          if (_looksLikeVideoRip(docTitle)) continue;
          final score = _score(docTitle, cleaned.toLowerCase());
          if (score < 0.4) continue;
          ranked.add((doc: doc, score: score));
        }
        ranked.sort((a, b) => b.score.compareTo(a.score));
        for (final hit in ranked) {
          final id = hit.doc['identifier'] as String;
          final art = await _artFromIdentifier(id, hit.doc);
          if (art != null) return art;
        }
      } catch (_) {
        // Best-effort — fall through to next query / procedural spine.
      }
    }
    return null;
  }

  Future<VhsSpineArt?> _artFromIdentifier(
    String id,
    Map<String, dynamic> doc,
  ) async {
    try {
      final meta = await _dio.get<Map<String, dynamic>>(
        'https://archive.org/metadata/$id',
      );
      final files = meta.data?['files'] as List<dynamic>? ?? const [];
      final pick = _pickScanFile(files);
      if (pick == null) return null;
      final name = pick.name;
      final url =
          'https://archive.org/download/$id/${Uri.encodeComponent(name)}';
      final title = (doc['title'] as String? ?? name).toLowerCase();
      final fraction = _spineFractionFor(name: name, title: title);
      return VhsSpineArt(imageUrl: url, centerWidthFraction: fraction);
    } catch (_) {
      // Thumbnail fallback — low res but better than nothing.
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
    // Flat sleeve / case scans → center strip is the spine.
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
      '${title.trim().toLowerCase()}|${year ?? ''}';

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
