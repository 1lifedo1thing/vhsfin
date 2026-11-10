// Runs the app's Jellyfin client against a real server. Skipped unless
// JELLYFIN_TEST_URL is set; `make jellyfin-compat` starts a seeded server
// (tool/jellyfin_server.sh) and runs this file.
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vhsfin/data/repositories/jellyfin_client.dart';
import 'package:vhsfin/features/auth/model/session.dart';
import 'package:vhsfin/features/library/data/sleeve_downscale.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/model/sleeve_shrink_status.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/library/state/sleeve_shrink.dart';

final _serverUrl = Platform.environment['JELLYFIN_TEST_URL'];

void main() {
  group(
    'live Jellyfin server',
    skip: _serverUrl == null ? 'JELLYFIN_TEST_URL is not set' : false,
    () {
      final client = JellyfinClient();
      // Plain requests, as the player and image widgets make them: auth
      // travels only in the URL.
      final http = Dio(
        BaseOptions(
          receiveTimeout: const Duration(seconds: 90),
          validateStatus: (_) => true,
        ),
      );
      late JellyfinSession session;
      late Tape movie;
      late Tape episode;

      setUpAll(() async {
        session = await client.authenticate(
          serverUrl: _serverUrl!,
          username: 'vhsfin',
          password: 'vhsfin',
        );
        final libraries = await client.fetchLibraries(session);
        LibraryNode library(String type) =>
            libraries.firstWhere((l) => l.collectionType == type);
        final movies = library('movies');
        final shows = library('tvshows');

        final movieShelf = await client.fetchShelfItems(
          session: session,
          source: ShelfSource(id: movies.id, name: movies.name),
        );
        movie = movieShelf.single;

        final showShelf = await client.fetchShelfItems(
          session: session,
          source: ShelfSource(id: shows.id, name: shows.name),
        );
        final series = showShelf.single;
        expect(series.kind, TapeKind.series);
        final episodes = await client.fetchEpisodes(
          session: session,
          seriesId: series.id,
          seriesTitle: series.title,
        );
        episode = episodes.single;
      });

      test('shelves list the seeded movie and episode', () {
        expect(movie.kind, TapeKind.movie);
        // Offline, Jellyfin names it after the folder: Test Movie (2001).
        expect(movie.title, startsWith('Test Movie'));
        expect(movie.duration, isNotNull);
        expect(episode.kind, TapeKind.episode);
        expect(episode.subtitle, 'S01E01');
      });

      Future<void> expectHlsPlays(String streamUrl) async {
        final master = Uri.parse(streamUrl);
        final playlist = await _get(http, master);
        final variant = master.resolve(_firstUri(playlist));
        final media = await _get(http, variant);
        final segment = variant.resolve(_firstUri(media));
        final bytes = await http.getUri<List<int>>(
          segment,
          options: Options(responseType: ResponseType.bytes),
        );
        expect(bytes.statusCode, 200, reason: 'first segment');
        expect(bytes.data, isNotEmpty);
        expect(bytes.data!.first, 0x47, reason: 'MPEG-TS sync byte');
      }

      test('native HLS stream serves its first segment (movie)', () async {
        await expectHlsPlays(movie.streamUrl);
      });

      test('native HLS stream serves its first segment (episode)', () async {
        await expectHlsPlays(episode.streamUrl);
      });

      test('web progressive stream starts', () async {
        final url = client.streamUrl(
          session,
          movie.id,
          transport: JellyfinStreamTransport.progressiveMp4,
        );
        final cancel = CancelToken();
        final response = await http.get<ResponseBody>(
          url,
          cancelToken: cancel,
          options: Options(responseType: ResponseType.stream),
        );
        expect(response.statusCode, anyOf(200, 206));
        final first = await response.data!.stream.first;
        cancel.cancel();
        expect(first, isNotEmpty);
      });

      test('image URLs are not rejected for auth', () async {
        // Generated clips have no artwork, so 404 is the expected answer;
        // the point is that the key is never refused.
        final response = await http.get<void>(
          client.primaryImageUrl(session, movie.id),
        );
        expect(response.statusCode, isNot(anyOf(401, 403)));
      });

      test('an oversized Box sleeve shrinks in place', () async {
        expect(await client.isAdministrator(session), isTrue);
        // A full-resolution scan, as sleeves were saved before 1.0.1.
        final scan = Uint8List.fromList(
          img.encodeJpg(_noise(2600, 2000), quality: 95),
        );
        expect(
          await client.saveBoxImage(
            session: session,
            itemId: movie.id,
            jpeg: scan,
            overwrite: true,
          ),
          isTrue,
        );
        expect(await client.fetchBoxImageItemIds(session), [movie.id]);
        expect(await client.boxImageInfo(session, movie.id), (
          width: 2600,
          height: 2000,
          bytes: scan.length,
          png: false,
        ));

        final shrinker = SleeveShrinker(client, session);
        addTearDown(shrinker.dispose);
        await shrinker.check();
        expect(shrinker.status.value.phase, SleeveShrinkPhase.ready);
        expect(shrinker.status.value.oversized, 1);
        await shrinker.shrink();
        expect(shrinker.status.value.phase, SleeveShrinkPhase.done);
        expect(shrinker.status.value.shrunk, 1);

        final after = (await client.boxImageInfo(session, movie.id))!;
        expect(after.height, sleeveMaxHeight);
        expect(after.bytes, lessThan(scan.length));
        final served = await http.get<void>(
          '${session.normalizedServerUrl}/Items/${movie.id}/Images/Box'
          '?maxHeight=900&quality=85&ApiKey=${session.accessToken}',
        );
        expect(served.statusCode, 200);
      });
    },
  );
}

/// Random pixels, so the JPEG stays as large as a real scan.
img.Image _noise(int width, int height) {
  final image = img.Image(width: width, height: height);
  var seed = 7;
  for (final p in image) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    p
      ..r = seed & 0xFF
      ..g = (seed >> 8) & 0xFF
      ..b = (seed >> 16) & 0xFF;
  }
  return image;
}

Future<String> _get(Dio http, Uri uri) async {
  final response = await http.getUri<String>(
    uri,
    options: Options(responseType: ResponseType.plain),
  );
  expect(response.statusCode, 200, reason: uri.path);
  return response.data!;
}

String _firstUri(String playlist) => playlist
    .split('\n')
    .map((line) => line.trim())
    .firstWhere((line) => line.isNotEmpty && !line.startsWith('#'));
