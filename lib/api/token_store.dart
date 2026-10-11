import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _kAccess = 'scamshield_access_token';
  static const String _kRefresh = 'scamshield_refresh_token';
  static const String _kExpiry = 'scamshield_access_expiry';

  final FlutterSecureStorage _storage;

  Future<String?> accessToken() => _storage.read(key: _kAccess);

  Future<String?> refreshToken() => _storage.read(key: _kRefresh);

  Future<DateTime?> accessExpiry() async {
    final raw = await _storage.read(key: _kExpiry);
    if (raw == null) return null;
    final ms = int.tryParse(raw);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiry = DateTime.now()
        .toUtc()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
    await _storage.write(key: _kExpiry, value: expiry.toString());
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiry);
  }

  Future<bool> hasSession() async {
    final refresh = await refreshToken();
    return refresh != null && refresh.isNotEmpty;
  }
}
