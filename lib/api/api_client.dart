import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

typedef RefreshCallback = Future<bool> Function();
typedef UnauthorizedCallback = Future<void> Function();

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.body,
    this.requestId,
  });

  final int statusCode;
  final Object? body;
  final String? requestId;

  Map<String, dynamic> get json =>
      body is Map<String, dynamic> ? body as Map<String, dynamic> : const {};

  List<dynamic> get list => body is List ? body as List : const [];
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStore? tokenStore,
    this.onRefresh,
    this.onUnauthorized,
  })  : _http = httpClient ?? http.Client(),
        _tokens = tokenStore ?? TokenStore();

  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _http;
  final TokenStore _tokens;

  RefreshCallback? onRefresh;
  UnauthorizedCallback? onUnauthorized;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('GET', path, query: query, auth: auth);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('POST', path, body: body, query: query, auth: auth);

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    bool auth = true,
  }) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<ApiResponse> put(
    String path, {
    Object? body,
    bool auth = true,
  }) =>
      _send('PUT', path, body: body, auth: auth);

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    bool auth = true,
  }) =>
      _send('DELETE', path, body: body, auth: auth);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = ApiConfig.uri(path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await _tokens.accessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _http.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw ApiException.network(error);
    }

    final requestId = response.headers['x-request-id'];

    if (response.statusCode == 401 &&
        auth &&
        !isRetry &&
        onRefresh != null) {
      final refreshed = await onRefresh!.call();
      if (refreshed) {
        return _send(
          method,
          path,
          body: body,
          query: query,
          auth: auth,
          isRetry: true,
        );
      }
      await onUnauthorized?.call();
    }

    final parsed = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 && auth) {
        await onUnauthorized?.call();
      }
      throw ApiException.fromResponse(
        response.statusCode,
        parsed is Map<String, dynamic>
            ? parsed
            : {'request_id': requestId},
      );
    }

    return ApiResponse(
      statusCode: response.statusCode,
      body: parsed,
      requestId: requestId,
    );
  }

  Object? _decode(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  void close() => _http.close();
}
