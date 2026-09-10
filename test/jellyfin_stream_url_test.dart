import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/data/repositories/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';

void main() {
  test('stream URL requests a browser-compatible progressive transcode', () {
    const session = JellyfinSession(
      serverUrl: 'http://jellyfin.local/',
      userId: 'user',
      userName: 'viewer',
      accessToken: 'token + /',
      deviceId: 'device-1',
    );

    final uri = Uri.parse(JellyfinClient().streamUrl(session, 'movie-1'));

    expect(uri.path, '/Videos/movie-1/stream.mp4');
    expect(uri.queryParameters['Static'], 'false');
    expect(uri.queryParameters['VideoCodec'], 'h264');
    expect(uri.queryParameters['AudioCodec'], 'aac');
    expect(uri.queryParameters['EnableAutoStreamCopy'], 'true');
    expect(uri.queryParameters['MaxWidth'], '1920');
    expect(uri.queryParameters['MaxHeight'], '1080');
    expect(uri.queryParameters['DeviceId'], 'device-1');
    expect(uri.queryParameters['api_key'], 'token + /');
  });
}
