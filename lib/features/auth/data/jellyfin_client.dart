import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/library/model/tape.dart';

/// Minimal Jellyfin REST client — auth + kids library browse + stream URLs.
class JellyfinClient {
  JellyfinClient({Dio? dio}) : _dio = dio ?? Dio();

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

  Future<List<Tape>> fetchKidsMovies(JellyfinSession session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${session.normalizedServerUrl}/Users/${session.userId}/Items',
      queryParameters: {
        'IncludeItemTypes': 'Movie,Episode',
        'Recursive': true,
        'SortBy': 'SortName',
        'SortOrder': 'Ascending',
        'Fields': 'PrimaryImageAspectRatio,Overview,RunTimeTicks',
        'Limit': 48,
      },
      options: Options(
        headers: {
          'Authorization': _authHeader(
            deviceId: session.deviceId,
            token: session.accessToken,
          ),
        },
      ),
    );

    final items = (response.data?['Items'] as List<dynamic>? ?? const []);
    return items.map((raw) {
      final item = raw as Map<String, dynamic>;
      final id = item['Id'] as String;
      final ticks = item['RunTimeTicks'] as int?;
      return Tape(
        id: id,
        title: item['Name'] as String? ?? 'Untitled',
        subtitle: item['SeriesName'] as String? ?? item['ProductionYear']?.toString(),
        streamUrl: streamUrl(session, id),
        imageUrl: primaryImageUrl(session, id),
        duration: ticks == null
            ? null
            : Duration(microseconds: ticks ~/ 10),
      );
    }).toList();
  }

  String streamUrl(JellyfinSession session, String itemId) {
    final base = session.normalizedServerUrl;
    return '$base/Videos/$itemId/stream'
        '?Static=true'
        '&api_key=${session.accessToken}';
  }

  String primaryImageUrl(JellyfinSession session, String itemId) {
    return '${session.normalizedServerUrl}/Items/$itemId/Images/Primary'
        '?maxHeight=400&quality=80';
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
