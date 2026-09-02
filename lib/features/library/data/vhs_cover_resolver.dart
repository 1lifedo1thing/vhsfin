import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Looks up period VHS box/cover art on Internet Archive and caches hits.
///
/// VHSCollector has no public API (skipped). IA has searchable cover scans +
/// `services/img/{id}` thumbnails — best-effort title match only.
class VhsCoverResolver {
  VhsCoverResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _cacheKey = 'vhsfin.ia_cover_cache.v1';
  static const _miss = '__miss__';

  final Map<String, String?> _memory = {};

  Future<String?> coverUrlFor({
    required String title,
    int? year,
  }) async {
    final key = _key(title, year);
    if (_memory.containsKey(key)) {
      final cached = _memory[key];
      return cached == _miss ? null : cached;
    }

    final prefs = await SharedPreferences.getInstance();
    final disk = _readDisk(prefs);
    if (disk.containsKey(key)) {
      final value = disk[key];
      _memory[key] = value;
      return value == _miss ? null : value;
    }

    final resolved = await _search(title, year);
    _memory[key] = resolved ?? _miss;
    disk[key] = resolved ?? _miss;
    await prefs.setString(_cacheKey, jsonEncode(disk));
    return resolved;
  }

  Future<String?> _search(String title, int? year) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return null;

    final queries = <String>[
      'title:("$cleaned") AND (title:("vhs cover") OR title:("VHS Cover"))',
      'title:("$cleaned") AND subject:(vhs) AND mediatype:image',
      if (year != null)
        'title:("$cleaned") AND year:$year AND (vhs OR videocassette)',
      'title:("$cleaned") AND (vhs OR videocassette) AND mediatype:(movies OR image)',
    ];

    for (final query in queries) {
      try {
        final url =
            'https://archive.org/advancedsearch.php'
            '?q=${Uri.encodeQueryComponent(query)}'
            '&fl[]=identifier&fl[]=title&rows=5&output=json';
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          options: Options(
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
          ),
        );
        final docs =
            response.data?['response']?['docs'] as List<dynamic>? ?? const [];
        for (final raw in docs) {
          final doc = raw as Map<String, dynamic>;
          final id = doc['identifier'] as String?;
          if (id == null || id.isEmpty) continue;
          // Prefer items that look like cover scans, not full VHS rips.
          final docTitle = (doc['title'] as String? ?? '').toLowerCase();
          final score = _score(docTitle, cleaned.toLowerCase());
          if (score < 0.35) continue;
          return 'https://archive.org/services/img/$id';
        }
      } catch (_) {
        // Best-effort — fall through to next query / procedural spine.
      }
    }
    return null;
  }

  double _score(String docTitle, String wanted) {
    if (docTitle.contains(wanted)) return 1;
    final wantedParts = wanted.split(RegExp(r'\s+')).where((w) => w.length > 2);
    if (wantedParts.isEmpty) return 0;
    var hits = 0;
    for (final part in wantedParts) {
      if (docTitle.contains(part)) hits++;
    }
    return hits / wantedParts.length;
  }

  String _key(String title, int? year) =>
      '${title.trim().toLowerCase()}|${year ?? ''}';

  Map<String, String?> _readDisk(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String?));
    } catch (_) {
      return {};
    }
  }
}

final vhsCoverResolverProvider = Provider<VhsCoverResolver>((ref) {
  return VhsCoverResolver();
});

final vhsCoverUrlProvider =
    FutureProvider.family<String?, ({String title, int? year})>((ref, args) {
  return ref.watch(vhsCoverResolverProvider).coverUrlFor(
        title: args.title,
        year: args.year,
      );
});
