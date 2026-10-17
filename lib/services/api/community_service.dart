import '../../api/api_client.dart';
import '../../models/api/community_models.dart';

class CommunityService {
  CommunityService(this._client);

  final ApiClient _client;

  Future<Paginated<FeedPost>> feed({
    String sort = 'recent',
    String? scamType,
    String? tag,
    int? limit,
    String? cursor,
  }) async {
    final response = await _client.get(
      '/community/feed',
      query: {
        'sort': sort,
        'scam_type': ?scamType,
        'tag': ?tag,
        'limit': ?limit,
        'cursor': ?cursor,
      },
    );
    return Paginated.fromJson(response.json, FeedPost.fromJson);
  }

  Future<Paginated<FeedPost>> search({
    required String query,
    String? scamType,
    int? limit,
    String? cursor,
  }) async {
    final response = await _client.get(
      '/community/feed/search',
      query: {
        'q': query,
        'scam_type': ?scamType,
        'limit': ?limit,
        'cursor': ?cursor,
      },
    );
    return Paginated.fromJson(response.json, FeedPost.fromJson);
  }

  Future<PostDetail> post(String postId) async {
    final response = await _client.get('/community/posts/$postId');
    return PostDetail.fromJson(response.json);
  }

  Future<Paginated<FeedPost>> myPosts({
    int? limit,
    String? cursor,
  }) async {
    final response = await _client.get(
      '/me/posts',
      query: {
        'limit': ?limit,
        'cursor': ?cursor,
      },
    );
    return Paginated.fromJson(response.json, FeedPost.fromJson);
  }

  /// Creates a community post. Attach analyzed screenshots by passing their
  /// [uploadIds] (from `POST /uploads`); each is sent in the `upload_ids`
  /// array. Poll the owner-only `GET /uploads/{upload_id}` before posting to
  /// ensure each upload has finished processing (OCR + redaction).
  Future<PostDetail> createPost({
    List<String> uploadIds = const [],
    required String title,
    required String redactedText,
    String? scamType,
    String locale = 'en-SG',
  }) async {
    final response = await _client.post(
      '/community/posts',
      body: {
        'upload_ids': uploadIds,
        'title': title,
        'redacted_text': redactedText,
        'scam_type': ?scamType,
        'confirm_publication': true,
        'locale': locale,
      },
    );
    return PostDetail.fromJson(response.json);
  }

  Future<PostDetail> updatePost({
    required String postId,
    String? title,
    String? redactedText,
  }) async {
    final response = await _client.patch(
      '/community/posts/$postId',
      body: {
        'title': ?title,
        'redacted_text': ?redactedText,
      },
    );
    return PostDetail.fromJson(response.json);
  }

  Future<void> deletePost(String postId) async {
    await _client.delete('/community/posts/$postId');
  }

  Future<ReactionResult> setReaction({
    required String postId,
    required int vote,
  }) async {
    final response = await _client.put(
      '/community/posts/$postId/reaction',
      body: {'vote': vote},
    );
    return ReactionResult.fromJson(response.json);
  }

  Future<ReactionResult> clearReaction(String postId) async {
    final response = await _client.delete('/community/posts/$postId/reaction');
    return ReactionResult.fromJson(response.json);
  }

  Future<FlagResult> flagPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    final response = await _client.post(
      '/community/posts/$postId/flag',
      body: {
        'reason': reason,
        'details': ?details,
      },
    );
    return FlagResult.fromJson(response.json);
  }

  Future<void> reportNumber({
    required String number,
    required String reason,
  }) async {
    await _client.post(
      '/community/number-reports',
      body: {
        'number': number,
        'reason': reason,
      },
    );
  }

  Future<Paginated<ScamCategory>> scamTypes() async {
    final response = await _client.get('/community/scam-types', auth: false);
    return Paginated.fromJson(response.json, ScamCategory.fromJson);
  }

  Future<Paginated<ScamTag>> tags({String? query, int? limit}) async {
    final response = await _client.get(
      '/community/tags',
      auth: false,
      query: {
        'q': ?query,
        'limit': ?limit,
      },
    );
    return Paginated.fromJson(response.json, ScamTag.fromJson);
  }
}
