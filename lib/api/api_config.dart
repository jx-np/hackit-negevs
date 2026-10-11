class ApiConfig {
  const ApiConfig._();

  static const String baseHost =
      'https://monarch-full-lizard.ngrok-free.app';

  static const String apiPrefix = '/api/v1';

  static String get baseUrl => '$baseHost$apiPrefix';

  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final cleaned = <String, String>{};
    if (query != null) {
      for (final entry in query.entries) {
        final value = entry.value;
        if (value == null) continue;
        cleaned[entry.key] = value.toString();
      }
    }
    return Uri.parse('$baseUrl$normalized').replace(
      queryParameters: cleaned.isEmpty ? null : cleaned,
    );
  }
}
