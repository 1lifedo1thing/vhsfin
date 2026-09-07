import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/model/tape.dart';

/// Minimal Jellyfin REST client — auth, views, shelves, streams.
class JellyfinClient {
  JellyfinClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;
  static const _appName = 'VHSFin';
  static const _appVersion = '0.1.0';

  String _authHeader({
    required String deviceId,
    String? token,
  }) {
    final parts = <String>[
      'MediaBrowser Client="$_appName"',
      'Device="VHSFin"',
      'DeviceId="$deviceId"',
      'Version="$_appVersion"',
      if (token != null) 'Token="$token"',
    ];
    return parts.join(', ');
  }

  Options _authed(JellyfinSession session) {
    return Options(
      headers: {
        'Authorization': _authHeader(
          deviceId: session.deviceId,
          token: session.accessToken,
        ),
      },
    );
  }

  Future<JellyfinSession> authenticate({
    required String serverUrl,
    required String username,
    required String password,
    String? deviceId,
  }) async {
    final id = deviceId ?? const Uuid().v4();
    final base = _normalize(serverUrl);

    final response = await _dio.post<Map<String, dynamic>>(
      '$base/Users/AuthenticateByName',
      data: {
        'Username': username,
        'Pw': password,
      },
      options: Options(
        headers: {
          'Authorization': _authHeader(deviceId: id),
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data!;
    final user = data['User'] as Map<String, dynamic>;
    return JellyfinSession(
      serverUrl: base,
      userId: user['Id'] as String,
      userName: user['Name'] as String,
      accessToken: data['AccessToken'] as String,
      deviceId: id,
    );
  }

  Future<List<LibraryNode>> fetchLibraries(JellyfinSession session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Views',
      options: _authed(session),
    );

    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items
        .map((raw) => LibraryNode.fromItem(raw as Map<String, dynamic>))
        .toList();
  }

  /// Non-recursive children — folders/box sets to drill into for shelf picking.
  Future<List<LibraryNode>> fetchBrowsableChildren({
    required JellyfinSession session,
    required String parentId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'ParentId': parentId,
        'Recursive': false,
        'SortBy': 'IsFolder,SortName',
        'SortOrder': 'Ascending',
        'Fields': 'ChildCount,CollectionType,PrimaryImageAspectRatio',
        'Limit': 300,
      },
      options: _authed(session),
    );

    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items
        .map((raw) => LibraryNode.fromItem(raw as Map<String, dynamic>))
        .where((node) => node.canBrowse)
        .toList();
  }

  /// Movies + series under a chosen shelf folder (recursive).
  Future<List<Tape>> fetchShelfItems({
    required JellyfinSession session,
    required ShelfSource source,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'ParentId': source.id,
        'IncludeItemTypes': 'Movie,Series',
        'Recursive': true,
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'Fields':
            'PrimaryImageAspectRatio,Overview,RunTimeTicks,ChildCount,ImageTags,'
                'ProductionYear,Genres,CommunityRating,OfficialRating',
        'Limit': 300,
      },
      options: _authed(session),
    );

    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items
        .map(
          (raw) => _tapeFromItem(
            raw as Map<String, dynamic>,
            session,
            source,
          ),
        )
        .toList();
  }

  Future<List<Tape>> fetchEpisodes({
    required JellyfinSession session,
    required String seriesId,
    String? libraryName,
    String? seriesTitle,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'ParentId': seriesId,
        'IncludeItemTypes': 'Episode',
        'Recursive': true,
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'Fields':
            'PrimaryImageAspectRatio,Overview,RunTimeTicks,IndexNumber,'
                'ParentIndexNumber,ImageTags,ProductionYear,SeriesName,Genres,'
                'CommunityRating,OfficialRating',
        'Limit': 400,
      },
      options: _authed(session),
    );

    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items.map((raw) {
      final item = raw as Map<String, dynamic>;
      final id = item['Id'] as String;
      final season = item['ParentIndexNumber'] as int?;
      final episode = item['IndexNumber'] as int?;
      final label = [
        if (season != null) 'S${season.toString().padLeft(2, '0')}',
        if (episode != null) 'E${episode.toString().padLeft(2, '0')}',
      ].join('');
      final resolvedSeries =
          seriesTitle ?? item['SeriesName'] as String? ?? libraryName;
      return Tape(
        id: id,
        title: item['Name'] as String? ?? 'Episode',
        subtitle: label.isEmpty ? resolvedSeries : label,
        streamUrl: streamUrl(session, id),
        imageUrl: primaryImageUrl(session, id),
        boxImageUrl: boxImageUrl(session, id, item),
        duration: _durationFromTicks(item['RunTimeTicks'] as int?),
        kind: TapeKind.episode,
        seriesId: seriesId,
        seriesTitle: resolvedSeries,
        seasonNumber: season,
        libraryName: libraryName,
        productionYear: item['ProductionYear'] as int?,
        overview: _overview(item),
        genres: _genres(item),
        communityRating: _communityRating(item),
        officialRating: item['OfficialRating'] as String?,
      );
    }).toList();
  }

  Tape _tapeFromItem(
    Map<String, dynamic> item,
    JellyfinSession session,
    ShelfSource source,
  ) {
    final id = item['Id'] as String;
    final type = item['Type'] as String? ?? 'Movie';
    final isSeries = type == 'Series';
    return Tape(
      id: id,
      title: item['Name'] as String? ?? 'Untitled',
      subtitle: isSeries
          ? '${item['ChildCount'] ?? '?'} eps'
          : item['ProductionYear']?.toString(),
      streamUrl: isSeries ? '' : streamUrl(session, id),
      imageUrl: primaryImageUrl(session, id),
      boxImageUrl: boxImageUrl(session, id, item),
      duration: _durationFromTicks(item['RunTimeTicks'] as int?),
      kind: isSeries ? TapeKind.series : TapeKind.movie,
      libraryId: source.id,
      libraryName: source.name,
      productionYear: item['ProductionYear'] as int?,
      episodeCount: item['ChildCount'] as int?,
      overview: _overview(item),
      genres: _genres(item),
      communityRating: _communityRating(item),
      officialRating: item['OfficialRating'] as String?,
    );
  }

  String? _overview(Map<String, dynamic> item) {
    final raw = item['Overview'] as String?;
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _genres(Map<String, dynamic> item) {
    final raw = item['Genres'];
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();
  }

  double? _communityRating(Map<String, dynamic> item) {
    final raw = item['CommunityRating'];
    if (raw is num) return raw.toDouble();
    return null;
  }

  Duration? _durationFromTicks(int? ticks) {
    if (ticks == null) return null;
    return Duration(microseconds: ticks ~/ 10);
  }

  String streamUrl(JellyfinSession session, String itemId) {
    final base = session.normalizedServerUrl;
    return '$base/Videos/$itemId/stream'
        '?Static=true'
        '&api_key=${session.accessToken}';
  }

  String primaryImageUrl(JellyfinSession session, String itemId) {
    return '${session.normalizedServerUrl}/Items/$itemId/Images/Primary'
        '?maxHeight=400&quality=80'
        '&api_key=${session.accessToken}';
  }

  /// VHS sleeve / box art — Jellyfin's `Box` image type (also `box.jpg` on disk).
  String? boxImageUrl(
    JellyfinSession session,
    String itemId,
    Map<String, dynamic> item,
  ) {
    final tags = item['ImageTags'];
    if (tags is! Map || tags['Box'] == null) return null;
    final tag = tags['Box'];
    return '${session.normalizedServerUrl}/Items/$itemId/Images/Box'
        '?tag=$tag&maxHeight=900&quality=85'
        '&api_key=${session.accessToken}';
  }

  /// Ask Jellyfin to download a remote sleeve scan and store it as `Box`
  /// (same family as posters — lives in library metadata; also mirrors what
  /// dropping `box.jpg` next to the media file would do after a scan).
  ///
  /// Never overwrites an existing Box image. Requires elevation to upload.
  Future<bool> saveBoxImageFromUrl({
    required JellyfinSession session,
    required String itemId,
    required String imageUrl,
  }) async {
    try {
      final existing = await _dio.get<Map<String, dynamic>>(
        '${session.normalizedServerUrl}/Users/${session.userId}/Items/$itemId',
        queryParameters: {'Fields': 'ImageTags'},
        options: _authed(session),
      );
      final tags = existing.data?['ImageTags'];
      if (tags is Map && tags['Box'] != null) {
        return false;
      }

      await _dio.post<void>(
        '${session.normalizedServerUrl}/Items/$itemId/RemoteImages/Download',
        queryParameters: {
          'Type': 'Box',
          'ImageUrl': imageUrl,
        },
        options: _authed(session),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove a stored `Box` image (e.g. after the user rejects a bad auto-match).
  Future<bool> deleteBoxImage({
    required JellyfinSession session,
    required String itemId,
  }) async {
    try {
      await _dio.delete<void>(
        '${session.normalizedServerUrl}/Items/$itemId/Images/Box',
        options: _authed(session),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _normalize(String url) {
    var value = url.trim();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
