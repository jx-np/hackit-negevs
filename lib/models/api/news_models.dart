/// A single scam-alert / news article shown on the home page.
///
/// The backend returns the title and body as per-locale maps (e.g.
/// `{"en": "...", "ms": "..."}`) so one payload serves every supported
/// language. Use [localizedTitle] / [localizedBody] to pick the string for the
/// active locale, falling back to English and then to whatever is available.
class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String id;

  /// Backend-provided icon key (snake_case), e.g. `message_square_warning`.
  /// Mapped to a glyph by the UI (see `newsIconFor`). Kept as a raw string so
  /// the model stays a plain data holder with no Flutter dependency.
  final String icon;

  /// Locale code -> title. Always expected to contain at least `en`.
  final Map<String, String> title;

  /// Locale code -> body text. Always expected to contain at least `en`.
  final Map<String, String> body;

  String localizedTitle(String locale) => _pick(title, locale);
  String localizedBody(String locale) => _pick(body, locale);

  /// Picks the string for [locale] (matching on the language subtag, so
  /// `en-SG` resolves to `en`), then English, then any available value.
  static String _pick(Map<String, String> values, String locale) {
    if (values.isEmpty) return '';
    final lang = locale.split(RegExp(r'[-_]')).first.toLowerCase();
    return values[locale] ??
        values[lang] ??
        values['en'] ??
        values.values.first;
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: '${json['id']}',
      icon: (json['icon'] as String?) ?? 'newspaper',
      title: _toStringMap(json['title']),
      body: _toStringMap(json['text']),
    );
  }

  static Map<String, String> _toStringMap(Object? value) {
    if (value is Map) {
      return value.map((key, v) => MapEntry('$key', '$v'));
    }
    return const {};
  }
}
