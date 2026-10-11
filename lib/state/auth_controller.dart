import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/token_store.dart';
import '../models/api/auth_models.dart';
import '../services/api/auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({
    required ApiClient client,
    AuthService? authService,
    TokenStore? tokenStore,
  })  : _client = client,
        _auth = authService ?? AuthService(client),
        _tokens = tokenStore ?? TokenStore() {
    _client.onRefresh = _handleRefresh;
    _client.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _client;
  final AuthService _auth;
  final TokenStore _tokens;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  Future<void> bootstrap() async {
    final hasSession = await _tokens.hasSession();
    if (!hasSession) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      _user = await _auth.me();
      _status = AuthStatus.signedIn;
    } on ApiException {
      await _tokens.clear();
      _user = null;
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      final session = await _auth.login(email: email, password: password);
      await _persist(session);
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String locale = 'en-SG',
  }) async {
    return _run(() async {
      final session = await _auth.register(
        email: email,
        password: password,
        displayName: displayName,
        locale: locale,
      );
      await _persist(session);
    });
  }

  Future<void> logout() async {
    final refresh = await _tokens.refreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _auth.logout(refresh);
      } on ApiException {
        _error = null;
      }
    }
    await _tokens.clear();
    _user = null;
    _error = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_status != AuthStatus.signedIn) return;
    try {
      _user = await _auth.me();
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _status = AuthStatus.signedIn;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _persist(AuthSession session) async {
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresIn: session.expiresIn,
    );
    _user = session.user;
  }

  Future<bool> _handleRefresh() async {
    final refresh = await _tokens.refreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final rotated = await _auth.refresh(refresh);
      await _tokens.save(
        accessToken: rotated.accessToken,
        refreshToken: rotated.refreshToken,
        expiresIn: rotated.expiresIn,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> _handleUnauthorized() async {
    await _tokens.clear();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
