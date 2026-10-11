class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.locale,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String locale;
  final DateTime? createdAt;

  bool get isModerator => role == 'moderator' || role == 'admin';
  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return AuthUser(
      id: '${json['id']}',
      email: (json['email'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'resident',
      locale: (json['locale'] as String?) ?? 'en-SG',
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const {},
      ),
      accessToken: (json['access_token'] as String?) ?? '',
      refreshToken: (json['refresh_token'] as String?) ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 900,
    );
  }
}

class TokenRefresh {
  const TokenRefresh({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory TokenRefresh.fromJson(Map<String, dynamic> json) {
    return TokenRefresh(
      accessToken: (json['access_token'] as String?) ?? '',
      refreshToken: (json['refresh_token'] as String?) ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 900,
    );
  }
}
