class JellyfinSession {
  const JellyfinSession({
    required this.serverUrl,
    required this.userId,
    required this.userName,
    required this.accessToken,
    required this.deviceId,
  });

  final String serverUrl;
  final String userId;
  final String userName;
  final String accessToken;
  final String deviceId;

  /// A stable, token-free namespace for preferences belonging to this account.
  String get preferenceScope =>
      Uri.encodeComponent('$normalizedServerUrl|$userId');

  String get normalizedServerUrl {
    var url = serverUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'userId': userId,
    'userName': userName,
    'accessToken': accessToken,
    'deviceId': deviceId,
  };

  factory JellyfinSession.fromJson(Map<String, dynamic> json) {
    return JellyfinSession(
      serverUrl: json['serverUrl'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      accessToken: json['accessToken'] as String,
      deviceId: json['deviceId'] as String,
    );
  }
}
