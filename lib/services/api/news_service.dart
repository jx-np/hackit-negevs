import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/models/api/news_models.dart';

/// Fetches scam-alert / news articles for the home page.
class NewsService {
  NewsService(this._client);

  final ApiClient _client;

  /// Returns the latest news / scam alerts.
  ///
  /// `GET /api/v1/news` responds with:
  /// ```json
  /// {
  ///   "articles": [
  ///     {
  ///       "id": "...",
  ///       "icon": "message_square_warning",
  ///       "title": { "en": "...", "ms": "...", "ta": "...", "zh": "..." },
  ///       "text":  { "en": "...", "ms": "...", "ta": "...", "zh": "..." }
  ///     }
  ///   ]
  /// }
  /// ```
  Future<List<NewsArticle>> fetchNews() async {
    final response = await _client.get('/news');
    final list = response.json['articles'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromJson)
        .toList(growable: false);
  }
}
