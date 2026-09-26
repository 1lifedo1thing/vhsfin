import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vhsfin/user_facing_error.dart';

void main() {
  RequestOptions opts() => RequestOptions(path: '/Users/AuthenticateByName');

  test('connection failures map to reachability copy', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ]) {
      final message = userFacingError(
        DioException(requestOptions: opts(), type: type),
      );
      expect(message, contains("Can't reach"));
      expect(message, isNot(contains('DioException')));
      expect(message, isNot(contains('RequestOptions')));
    }
  });

  test('401/403 map to credentials copy', () {
    final message = userFacingError(
      DioException(
        requestOptions: opts(),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: opts(), statusCode: 401),
      ),
    );
    expect(message.toLowerCase(), contains('password'));
    expect(message, isNot(contains('401')));
  });

  test('404 and 5xx map without dumping status bodies', () {
    expect(
      userFacingError(
        DioException(
          requestOptions: opts(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: opts(), statusCode: 404),
        ),
      ),
      contains("Couldn't find"),
    );
    expect(
      userFacingError(
        DioException(
          requestOptions: opts(),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: opts(), statusCode: 502),
        ),
      ),
      contains('server error'),
    );
  });

  test('cancel gets a soft message', () {
    expect(
      userFacingError(
        DioException(requestOptions: opts(), type: DioExceptionType.cancel),
      ),
      'Request cancelled.',
    );
  });

  test('raw DioException toString dumps are sanitized', () {
    final dump = DioException(
      requestOptions: opts(),
      type: DioExceptionType.connectionTimeout,
    ).toString();
    expect(dump, contains('DioException'));
    expect(userFacingError(dump), isNot(contains('DioException')));
    expect(userFacingError(dump), isNot(contains('uri:')));
  });

  test('unknown Dio uses fallback without request internals', () {
    final message = userFacingError(
      DioException(requestOptions: opts(), type: DioExceptionType.unknown),
    );
    expect(message, 'Something went wrong. Please try again.');
  });
}
