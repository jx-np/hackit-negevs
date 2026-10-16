import 'dart:convert';

import 'package:scamwatch_mobile_app/models/api/news_models.dart';

/// Fetches scam-alert / news articles for the home page.
///
/// Currently returns hard-coded sample data so the UI is fully wired and ready.
/// When the backend endpoint is live, replace the body of [fetchNews] with a
/// real HTTP call:
///
/// ```dart
/// Future<List<NewsArticle>> fetchNews() async {
///   final response = await _client.get('/news');
///   final list = response.json['articles'] as List<dynamic>;
///   return list
///       .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
///       .toList();
/// }
/// ```
class NewsService {
  // TODO: Accept an ApiClient when the backend endpoint exists.
  // NewsService(this._client);
  // final ApiClient _client;

  /// Returns the latest news / scam alerts.
  ///
  /// The JSON shape mirrors what the backend will return:
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
    // Simulate network latency so any loading state is exercised.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final payload = jsonDecode(_fakePayload) as Map<String, dynamic>;
    final list = payload['articles'] as List<dynamic>;
    return list
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// ──────────────────────────────────────────────────────────────────────────
/// Fake JSON payload — remove once the real endpoint is live.
/// The `icon` values are mapped to LucideIcons by the UI layer.
/// ──────────────────────────────────────────────────────────────────────────
const String _fakePayload = '''
{
  "articles": [
    {
      "id": "news-1",
      "icon": "message_square_warning",
      "title": {
        "en": "Fake bank SMS on the rise",
        "ms": "SMS bank palsu semakin meningkat",
        "ta": "போலி வங்கி SMS அதிகரிப்பு",
        "zh": "假银行短信增多"
      },
      "text": {
        "en": "Scammers are sending texts that look like your bank. Never tap links in a text message.",
        "ms": "Penipu menghantar mesej yang kelihatan seperti bank anda. Jangan klik pautan dalam mesej.",
        "ta": "மோசடி செய்பவர்கள் உங்கள் வங்கியிலிருந்து வருவது போல் செய்திகள் அனுப்புகிறார்கள். செய்தியில் உள்ள இணைப்புகளைத் தட்ட வேண்டாம்.",
        "zh": "诈骗者发送看起来像银行的短信。切勿点击短信中的链接。"
      }
    },
    {
      "id": "news-2",
      "icon": "package",
      "title": {
        "en": "Parcel delivery scams",
        "ms": "Penipuan penghantaran bungkusan",
        "ta": "பார்சல் டெலிவரி மோசடிகள்",
        "zh": "包裹递送骗局"
      },
      "text": {
        "en": "Getting a message about a package you didn't order? Don't click the link — it's a common trick to steal your details.",
        "ms": "Menerima mesej tentang bungkusan yang tidak anda pesan? Jangan klik pautan — ia satu helah biasa untuk mencuri maklumat anda.",
        "ta": "நீங்கள் ஆர்டர் செய்யாத பார்சல் பற்றிய செய்தி வருகிறதா? இணைப்பைத் தட்ட வேண்டாம் — இது உங்கள் தகவலைத் திருட ஒரு பொதுவான தந்திரம்.",
        "zh": "收到一条关于你没有订购的包裹的消息？不要点击链接——这是窃取你信息的常见伎俩。"
      }
    },
    {
      "id": "news-3",
      "icon": "phone_call",
      "title": {
        "en": "Government impersonation calls",
        "ms": "Panggilan penyamaran kerajaan",
        "ta": "அரசு ஆள்மாறாட்ட அழைப்புகள்",
        "zh": "冒充政府来电"
      },
      "text": {
        "en": "No government agency will ask for your PIN or password over the phone. Hang up and call the official number.",
        "ms": "Tiada agensi kerajaan akan meminta PIN atau kata laluan anda melalui telefon. Tutup dan hubungi nombor rasmi.",
        "ta": "எந்த அரசு நிறுவனமும் தொலைபேசியில் உங்கள் PIN அல்லது கடவுச்சொல்லைக் கேட்காது. தொலைபேசியை வைத்துவிட்டு அதிகாரப்பூர்வ எண்ணை அழைக்கவும்.",
        "zh": "没有政府机构会通过电话索要您的PIN或密码。挂断电话并拨打官方号码。"
      }
    }
  ]
}
''';
