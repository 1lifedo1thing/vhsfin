import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/data/repositories/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';

void main() {
  const session = JellyfinSession(
    serverUrl: 'http://jellyfin.local/',
    userId: 'user',
    userName: 'viewer',
    accessToken: 'token + /',
    deviceId: 'device-1',
  );

  test('native stream URL uses seekable VOD HLS', () {
    final uri = Uri.parse(
      JellyfinClient().streamUrl(
        session,
        'movie-1',
        transport: JellyfinStreamTransport.hls,
      ),
    );

    expect(uri.path, '/Videos/movie-1/master.m3u8');
    expect(uri.queryParameters['MediaSourceId'], 'movie-1');
    expect(uri.queryParameters['SegmentContainer'], 'ts');
    expect(uri.queryParameters['MinSegments'], '1');
    expect(uri.queryParameters['VideoCodec'], 'h264');
    expect(uri.queryParameters['AudioCodec'], 'aac');
    expect(
      uri.queryParameters['MaxAudioChannels'],
      '6',
      reason: 'mpv downmixes',
    );
    expect(uri.queryParameters['DeviceId'], 'device-1');
    expect(uri.queryParameters['api_key'], 'token + /');
    expect(uri.queryParameters.containsKey('Static'), isFalse);
  });

  test('web stream URL keeps browser-compatible progressive MP4', () {
    final uri = Uri.parse(
      JellyfinClient().streamUrl(
        session,
        'movie-1',
        transport: JellyfinStreamTransport.progressiveMp4,
      ),
    );

    expect(uri.path, '/Videos/movie-1/stream.mp4');
    expect(uri.queryParameters['Static'], 'false');
    expect(uri.queryParameters['VideoCodec'], 'h264');
    expect(uri.queryParameters['AudioCodec'], 'aac');
    expect(uri.queryParameters['EnableAutoStreamCopy'], 'true');
    expect(uri.queryParameters['MaxWidth'], '1920');
    expect(uri.queryParameters['MaxHeight'], '1080');
    expect(uri.queryParameters['MaxAudioChannels'], '2');
    expect(uri.queryParameters['DeviceId'], 'device-1');
    expect(uri.queryParameters['api_key'], 'token + /');
  });
}
