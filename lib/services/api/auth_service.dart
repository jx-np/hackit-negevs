import '../../api/api_client.dart';
import '../../models/api/auth_models.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
    String locale = 'en-SG',
  }) async {
    final response = await _client.post(
      '/auth/register',
      auth: false,
      body: {
        'email': email,
        'password': password,
        'display_name': displayName,
        'locale': locale,
      },
    );
    return AuthSession.fromJson(response.json);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(response.json);
  }

  Future<TokenRefresh> refresh(String refreshToken) async {
    final response = await _client.post(
      '/auth/refresh',
      auth: false,
      body: {'refresh_token': refreshToken},
    );
    return TokenRefresh.fromJson(response.json);
  }

  Future<void> logout(String refreshToken) async {
    await _client.post(
      '/auth/logout',
      auth: false,
      body: {'refresh_token': refreshToken},
    );
  }

  Future<AuthUser> me() async {
    final response = await _client.get('/me');
    return AuthUser.fromJson(response.json);
  }
}
