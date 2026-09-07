import 'package:dio/dio.dart';

/// Maps API / network failures to short copy for the UI.
///
/// Never returns Dio dumps, request options, or stack-ish strings.
String userFacingError(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error == null) return fallback;
  if (error is DioException) return _fromDio(error, fallback);
  return _sanitize(error.toString(), fallback);
}

String _fromDio(DioException error, String fallback) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return "Can't reach the Jellyfin server. Check the URL and your network.";
    case DioExceptionType.badCertificate:
      return "Can't make a secure connection to the server.";
    case DioExceptionType.cancel:
      return 'Request cancelled.';
    case DioExceptionType.badResponse:
      return _fromStatus(error.response?.statusCode, fallback);
    case DioExceptionType.unknown:
      final nested = error.error;
      if (nested != null && nested is! DioException) {
        final nestedMessage = userFacingError(nested, fallback: fallback);
        if (nestedMessage != fallback) return nestedMessage;
      }
      return fallback;
  }
}

String _fromStatus(int? status, String fallback) {
  if (status == null) return fallback;
  if (status == 401 || status == 403) {
    return 'Wrong username or password, or this account is not allowed.';
  }
  if (status == 404) return "Couldn't find that on the server.";
  if (status >= 500 && status <= 599) {
    return 'Jellyfin had a server error. Try again in a moment.';
  }
  if (status >= 400 && status <= 499) {
    return 'The server rejected that request.';
  }
  return fallback;
}

String _sanitize(String raw, String fallback) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return fallback;
  if (trimmed.contains('DioException') ||
      trimmed.contains('DioError') ||
      trimmed.contains('RequestOptions') ||
      trimmed.contains('uri:') ||
      trimmed.contains('\n') ||
      trimmed.length > 140) {
    return fallback;
  }
  const prefixes = ['Exception: ', 'Error: ', 'Bad state: '];
  var message = trimmed;
  for (final prefix in prefixes) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length);
      break;
    }
  }
  if (message.isEmpty || message.startsWith('Instance of ')) return fallback;
  return message;
}
