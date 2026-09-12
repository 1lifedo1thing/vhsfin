/// Validates the base address without dropping reverse-proxy path prefixes.
String normalizeServerAddress(String value) {
  final raw = value.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      RegExp(r'\s').hasMatch(raw)) {
    throw const FormatException(
      'Enter a full server address, such as http://jellyfin.local:8096.',
    );
  }
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
    throw const FormatException(
      'Use the server address only, without a login, query, or # section.',
    );
  }
  return raw.replaceFirst(RegExp(r'/+$'), '');
}
