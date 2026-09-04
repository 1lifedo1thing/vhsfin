import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-tape sleeve rejections — wrong VHSCollector/IA matches (and bad Boxes).
class VhsArtRejection {
  const VhsArtRejection({
    required this.tapeId,
    this.blockedUrls = const {},
    this.ignoredBoxTag,
    this.suppressArt = true,
  });

  final String tapeId;
  final Set<String> blockedUrls;

  /// When set, ignore Jellyfin Box only while its ImageTags.Box matches.
  /// A newly uploaded correct Box (new tag) is allowed through.
  final String? ignoredBoxTag;

  /// After "Wrong sleeve", never show remote/Box art for this tape — printed
  /// spine only. URL/tag blocks alone are not enough: the same sleeve can
  /// return under a collector URL after a Box is ignored.
  final bool suppressArt;

  Map<String, dynamic> toJson() => {
        'id': tapeId,
        'urls': blockedUrls.toList(),
        if (ignoredBoxTag != null) 'boxTag': ignoredBoxTag,
        'suppress': suppressArt,
      };

  factory VhsArtRejection.fromJson(Map<String, dynamic> json) {
    final urls = json['urls'];
    return VhsArtRejection(
      tapeId: json['id'] as String,
      blockedUrls: {
        if (urls is List)
          for (final u in urls)
            if (u is String && u.isNotEmpty) normalizeArtUrl(u),
      },
      ignoredBoxTag: json['boxTag'] as String?,
      // Older records omit `suppress` — any stored rejection still means
      // the user rejected art for this tape.
      suppressArt: json['suppress'] as bool? ?? true,
    );
  }

  VhsArtRejection copyWith({
    Set<String>? blockedUrls,
    String? ignoredBoxTag,
    bool clearIgnoredBoxTag = false,
    bool? suppressArt,
  }) {
    return VhsArtRejection(
      tapeId: tapeId,
      blockedUrls: blockedUrls ?? this.blockedUrls,
      ignoredBoxTag:
          clearIgnoredBoxTag ? null : (ignoredBoxTag ?? this.ignoredBoxTag),
      suppressArt: suppressArt ?? this.suppressArt,
    );
  }
}

/// Strip volatile query params so the same sleeve still matches when
/// maxHeight / api_key / cache-busters change.
String normalizeArtUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return url.trim();
  // Keep `tag` for Jellyfin images — that's the real identity.
  final tag = uri.queryParameters['tag'];
  return uri.replace(
    queryParameters: {
      if (tag != null && tag.isNotEmpty) 'tag': tag,
    },
  ).toString();
}

String? boxTagFromUrl(String? boxImageUrl) {
  if (boxImageUrl == null || boxImageUrl.isEmpty) return null;
  return Uri.tryParse(boxImageUrl)?.queryParameters['tag'];
}

final vhsArtRejectsProvider =
    NotifierProvider<VhsArtRejectsNotifier, Map<String, VhsArtRejection>>(
  VhsArtRejectsNotifier.new,
);

class VhsArtRejectsNotifier extends Notifier<Map<String, VhsArtRejection>> {
  static const _key = 'vhsfin.spine_rejects.v1';

  int _epoch = 0;
  Completer<void> _ready = Completer<void>();

  /// Completes after the first prefs restore (or immediately if already done).
  Future<void> get ready => _ready.future;

  @override
  Map<String, VhsArtRejection> build() {
    _ready = Completer<void>();
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final epoch = _epoch;
    final ready = _ready;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (epoch != _epoch) return;
      final raw = prefs.getString(_key);
      if (raw == null) return;
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final map = <String, VhsArtRejection>{};
        for (final entry in list) {
          if (entry is! Map<String, dynamic>) continue;
          final rejection = VhsArtRejection.fromJson(entry);
          map[rejection.tapeId] = rejection;
        }
        state = map;
      } catch (_) {
        await prefs.remove(_key);
      }
    } finally {
      if (!ready.isCompleted) ready.complete();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = state.values.map((r) => r.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  /// Record a mismatch: suppress all sleeve art for this tape, and remember
  /// the bad URLs / Box tag so a resurrected Box with the same tag stays out.
  Future<void> reject({
    required String tapeId,
    required String imageUrl,
    String? boxImageUrl,
    String? boxTag,
  }) async {
    _epoch++;
    final existing = state[tapeId];
    final next = VhsArtRejection(
      tapeId: tapeId,
      blockedUrls: {
        ...?existing?.blockedUrls,
        normalizeArtUrl(imageUrl),
        if (boxImageUrl != null && boxImageUrl.isNotEmpty)
          normalizeArtUrl(boxImageUrl),
      },
      ignoredBoxTag: boxTag ?? existing?.ignoredBoxTag,
      suppressArt: true,
    );
    state = {...state, tapeId: next};
    await _persist();
  }

  /// User marked this tape's sleeve wrong — use the printed spine only.
  bool shouldSuppressArt(String tapeId) {
    final rejection = state[tapeId];
    return rejection != null && rejection.suppressArt;
  }

  bool isUrlBlocked(String tapeId, String imageUrl) {
    final rejection = state[tapeId];
    if (rejection == null) return false;
    return rejection.blockedUrls.contains(normalizeArtUrl(imageUrl));
  }

  bool shouldIgnoreBox(String tapeId, String? boxImageUrl) {
    final rejection = state[tapeId];
    if (rejection == null || boxImageUrl == null || boxImageUrl.isEmpty) {
      return false;
    }
    if (rejection.suppressArt) return true;
    if (rejection.blockedUrls.contains(normalizeArtUrl(boxImageUrl))) {
      return true;
    }
    final tag = boxTagFromUrl(boxImageUrl);
    if (rejection.ignoredBoxTag != null && tag == rejection.ignoredBoxTag) {
      return true;
    }
    return false;
  }
}
