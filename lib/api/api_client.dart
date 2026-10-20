import 'dart:convert';
import 'dart:typed_data';

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

/// One dispatched Server-Sent Event: its `event:` name (defaults to
/// `message`) and the joined `data:` payload.
class SseEvent {
  const SseEvent({required this.event, required this.data});

  final String event;
  final String data;
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

  /// Returns request headers carrying the current bearer token, suitable for
  /// authenticated reads made outside this client (e.g. `Image.network` for
  /// owner-only redacted post images). Empty when there is no session.
  Future<Map<String, String>> authHeaders() async {
    final token = await _tokens.accessToken();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  /// Whether a bearer access token is physically present in storage right now.
  ///
  /// This is stronger than the `AuthController.isSignedIn` UI flag: it confirms
  /// a token can actually be attached to the next request. Callers that create
  /// server resources which can only be read back by their authenticated owner
  /// (e.g. a `/uploads` detection check polled via an owner-only endpoint) use
  /// this to refuse to proceed anonymously.
  Future<bool> hasAccessToken() async {
    final token = await _tokens.accessToken();
    return token != null && token.isNotEmpty;
  }

  /// Sends a `multipart/form-data` request. [files] maps a form field name to
  /// the file to attach; [fields] carries any extra text fields. Reuses the
  /// same auth, 401-refresh retry, and error handling as JSON requests.
  Future<ApiResponse> multipart(
    String path, {
    required Map<String, http.MultipartFile> files,
    Map<String, String> fields = const {},
    String method = 'POST',
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = ApiConfig.uri(path);
    final headers = <String, String>{'Accept': 'application/json'};
    if (auth) {
      final token = await _tokens.accessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final request = http.MultipartRequest(method, uri)
        ..headers.addAll(headers)
        ..fields.addAll(fields)
        ..files.addAll(files.values);
      final streamed = await _http.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw ApiException.network(error);
    }

    final requestId = response.headers['x-request-id'];

    if (response.statusCode == 401 && auth && !isRetry && onRefresh != null) {
      final refreshed = await onRefresh!.call();
      if (refreshed) {
        return multipart(
          path,
          files: files,
          fields: fields,
          method: method,
          auth: auth,
          isRetry: true,
        );
      }
      await onUnauthorized?.call();
    }

    return _handle(response, requestId, auth: auth);
  }

  /// Fetches a raw, non-JSON response body — e.g. the owner-only redacted
  /// screenshot streamed as image bytes, which can't be decoded as JSON.
  /// Applies the same auth, 401-refresh retry, and error handling as [_send],
  /// but returns the undecoded [Uint8List] instead of an [ApiResponse]. A
  /// non-2xx still throws an [ApiException] built from the (JSON) error body.
  Future<Uint8List> getBytes(
    String path, {
    bool auth = true,
    bool isRetry = false,
  }) async {
    final uri = ApiConfig.uri(path);
    final headers = <String, String>{'Accept': '*/*'};
    if (auth) {
      final token = await _tokens.accessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    try {
      final request = http.Request('GET', uri)..headers.addAll(headers);
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
        return getBytes(path, auth: auth, isRetry: true);
      }
      await onUnauthorized?.call();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Object? parsed =
          _decode(utf8.decode(response.bodyBytes, allowMalformed: true));
      throw ApiException.fromResponse(
        response.statusCode,
        parsed is Map<String, dynamic>
            ? parsed
            : {'request_id': requestId},
      );
    }

    return response.bodyBytes;
  }

  /// Opens a Server-Sent Events stream at [path] and yields each event.
  ///
  /// Uses a dedicated HTTP client so cancelling the subscription tears the
  /// connection down. The server sends a keepalive every ~15s, so a stream
  /// idle for longer than [idleTimeout] errors out and the caller should
  /// reconnect. A non-2xx response throws an [ApiException].
  ///
  /// Authenticates like every other request on this client: the bearer token
  /// is attached when [auth] is set, and a 401 triggers a single token-refresh
  /// retry via [onRefresh] before giving up (surfacing `onUnauthorized`).
  Stream<SseEvent> sse(
    String path, {
    Duration idleTimeout = const Duration(seconds: 45),
    bool auth = true,
  }) async* {
    // The retry loop re-opens the whole stream once after a token refresh.
    var isRetry = false;
    while (true) {
      final client = http.Client();
      try {
        http.StreamedResponse response;
        try {
          final headers = <String, String>{
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          };
          if (auth) {
            final token = await _tokens.accessToken();
            if (token != null && token.isNotEmpty) {
              headers['Authorization'] = 'Bearer $token';
            }
          }
          final request = http.Request('GET', ApiConfig.uri(path))
            ..headers.addAll(headers);
          response = await client.send(request).timeout(_timeout);
        } catch (error) {
          throw ApiException.network(error);
        }

        if (response.statusCode == 401 && auth && !isRetry && onRefresh != null) {
          // Drain then close before re-authenticating so the socket is freed.
          await response.stream.bytesToString();
          final refreshed = await onRefresh!.call();
          if (refreshed) {
            isRetry = true;
            continue;
          }
          await onUnauthorized?.call();
          throw ApiException.fromResponse(
            response.statusCode,
            {'request_id': response.headers['x-request-id']},
          );
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          final raw = await response.stream.bytesToString();
          final Object? parsed = _decode(raw);
          throw ApiException.fromResponse(
            response.statusCode,
            parsed is Map<String, dynamic>
                ? parsed
                : {'request_id': response.headers['x-request-id']},
          );
        }

        String? event;
        final data = <String>[];
        final lines = response.stream
            .timeout(idleTimeout)
            .transform(utf8.decoder)
            .transform(const LineSplitter());
        await for (final line in lines) {
          if (line.isEmpty) {
            if (data.isNotEmpty) {
              yield SseEvent(event: event ?? 'message', data: data.join('\n'));
            }
            event = null;
            data.clear();
            continue;
          }
          if (line.startsWith(':')) continue;
          final colon = line.indexOf(':');
          final field = colon < 0 ? line : line.substring(0, colon);
          var value = colon < 0 ? '' : line.substring(colon + 1);
          if (value.startsWith(' ')) value = value.substring(1);
          if (field == 'event') {
            event = value;
          } else if (field == 'data') {
            data.add(value);
          }
        }
        // Stream ended cleanly; do not retry.
        return;
      } finally {
        client.close();
      }
    }
  }

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

    return _handle(response, requestId, auth: auth);
  }

  Future<ApiResponse> _handle(
    http.Response response,
    String? requestId, {
    bool auth = true,
  }) async {
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
