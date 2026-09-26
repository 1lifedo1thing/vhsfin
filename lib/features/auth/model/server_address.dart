/// Validates the base address without dropping reverse-proxy path prefixes.
String normalizeServerAddress(String value) {
  final raw = value.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      RegExp(r'\s').hasMatch(raw)) {
    throw const FormatException(
      'Enter your server address, such as jellyfin.local:8096.',
    );
  }
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
    throw const FormatException(
      'Use the server address only, without a login, query, or # section.',
    );
  }
  return raw.replaceFirst(RegExp(r'/+$'), '');
}

final _hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

/// Addresses to try for what the person typed, most secure first.
///
/// `jellyfin.local:8096` becomes `https://…` then `http://…`; an address that
/// already names its scheme is used as typed. When the app itself is served
/// over HTTPS, browsers block plain HTTP, so only HTTPS is offered.
List<String> serverAddressCandidates(String value, {bool httpsOnly = false}) {
  final raw = value.trim();
  if (raw.isEmpty || _hasScheme.hasMatch(raw)) {
    return [normalizeServerAddress(raw)];
  }
  return [
    normalizeServerAddress('https://$raw'),
    if (!httpsOnly) normalizeServerAddress('http://$raw'),
  ];
}
