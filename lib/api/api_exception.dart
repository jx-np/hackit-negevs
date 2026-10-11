class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fields = const {},
    this.requestId,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, String> fields;
  final String? requestId;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;

  factory ApiException.fromResponse(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    final error = body['error'];
    final errorMap = error is Map<String, dynamic> ? error : const {};
    final rawFields = errorMap['fields'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        fields['$key'] = '$value';
      });
    }
    return ApiException(
      statusCode: statusCode,
      code: (errorMap['code'] as String?) ?? _defaultCode(statusCode),
      message: (errorMap['message'] as String?) ?? _defaultMessage(statusCode),
      fields: fields,
      requestId: body['request_id'] as String?,
    );
  }

  factory ApiException.network(Object error) => ApiException(
        statusCode: 0,
        code: 'network_error',
        message: 'Could not reach the server. Check your connection.',
        fields: const {},
        requestId: error.toString(),
      );

  static String _defaultCode(int status) {
    switch (status) {
      case 400:
        return 'bad_request';
      case 401:
        return 'unauthorized';
      case 403:
        return 'forbidden';
      case 404:
        return 'not_found';
      case 409:
        return 'conflict';
      case 422:
        return 'unprocessable_entity';
      case 429:
        return 'rate_limited';
      default:
        return 'internal_error';
    }
  }

  static String _defaultMessage(int status) {
    switch (status) {
      case 401:
        return 'Please sign in again.';
      case 403:
        return 'You are not allowed to do that.';
      case 404:
        return 'That could not be found.';
      case 409:
        return 'That already exists.';
      case 422:
        return 'Some details were not valid.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}
