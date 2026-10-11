import '../../api/api_client.dart';
import '../../models/api/community_models.dart';

class DiscussionService {
  DiscussionService(this._client);

  final ApiClient _client;

  Future<Paginated<PostComment>> comments({
    required String postId,
    int? limit,
    String? cursor,
  }) async {
    final response = await _client.get(
      '/community/discussion/posts/$postId/comments',
      query: {
        'limit': ?limit,
        'cursor': ?cursor,
      },
    );
    return Paginated.fromJson(response.json, PostComment.fromJson);
  }

  Future<PostComment> addComment({
    required String postId,
    required String body,
    String? parentId,
  }) async {
    final response = await _client.post(
      '/community/discussion/posts/$postId/comments',
      body: {
        'body': body,
        'parent_id': ?parentId,
      },
    );
    return PostComment.fromJson(response.json);
  }

  Future<PostComment> editComment({
    required String commentId,
    required String body,
  }) async {
    final response = await _client.patch(
      '/community/discussion/comments/$commentId',
      body: {'body': body},
    );
    return PostComment.fromJson(response.json);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.delete('/community/discussion/comments/$commentId');
  }

  Future<FlagResult> flagComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    final response = await _client.post(
      '/community/discussion/comments/$commentId/flag',
      body: {
        'reason': reason,
        'details': ?details,
      },
    );
    return FlagResult.fromJson(response.json);
  }
}
