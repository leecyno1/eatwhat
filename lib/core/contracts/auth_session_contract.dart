class AuthSessionResponse {
  const AuthSessionResponse({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAt;
  final Map<String, dynamic> user;

  static AuthSessionResponse? tryParse(dynamic payload) {
    if (payload is! Map) return null;
    try {
      final json = Map<String, dynamic>.from(payload);
      final accessToken = json['accessToken']?.toString() ?? '';
      final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
      final rawUser = json['user'];
      if (accessToken.isEmpty || expiresAt == null || rawUser is! Map) {
        return null;
      }
      return AuthSessionResponse(
        accessToken: accessToken,
        expiresAt: expiresAt,
        user: Map<String, dynamic>.from(rawUser),
      );
    } on Object {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'expiresAt': expiresAt.toIso8601String(),
        'user': user,
      };
}
