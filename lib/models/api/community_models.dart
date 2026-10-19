import 'package:scamwatch_mobile_app/api/api_config.dart';

class Paginated<T> {
  const Paginated({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => (nextCursor ?? '').isNotEmpty;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) build,
  ) {
    final raw = json['items'];
    final items = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(build)
            .toList(growable: false)
        : <T>[];
    final cursor = json['next_cursor'] as String?;
    return Paginated(
      items: items,
      nextCursor: (cursor != null && cursor.isNotEmpty) ? cursor : null,
    );
  }
}

class ScamCategory {
  const ScamCategory({
    required this.slug,
    required this.nameKey,
    this.descriptionKey,
  });

  final String slug;
  final String nameKey;
  final String? descriptionKey;

  String get displayName => _humanize(nameKey);

  factory ScamCategory.fromJson(Map<String, dynamic> json) {
    return ScamCategory(
      slug: (json['slug'] as String?) ?? '',
      nameKey: (json['name_key'] as String?) ?? '',
      descriptionKey: json['description_key'] as String?,
    );
  }
}

class ScamTag {
  const ScamTag({required this.slug, required this.nameKey});

  final String slug;
  final String nameKey;

  String get displayName => _humanize(nameKey);

  factory ScamTag.fromJson(Map<String, dynamic> json) {
    return ScamTag(
      slug: (json['slug'] as String?) ?? '',
      nameKey: (json['name_key'] as String?) ?? '',
    );
  }
}

class PostReactions {
  const PostReactions({required this.up, required this.down});

  final int up;
  final int down;

  factory PostReactions.fromJson(Map<String, dynamic> json) {
    return PostReactions(
      up: (json['up'] as num?)?.toInt() ?? 0,
      down: (json['down'] as num?)?.toInt() ?? 0,
    );
  }
}

class FeedPost {
  const FeedPost({
    required this.postId,
    required this.title,
    required this.redactedExcerpt,
    required this.category,
    required this.tags,
    required this.reviewStatus,
    required this.createdAt,
    required this.commentCount,
    this.reactions = const PostReactions(up: 0, down: 0),
    this.myVote = 0,
  });

  final String postId;
  final String title;
  final String redactedExcerpt;
  final ScamCategory? category;
  final List<ScamTag> tags;
  final String reviewStatus;
  final DateTime? createdAt;
  final int commentCount;

  /// The post's up/down vote counts. The feed, search, and my-posts list all
  /// carry the same `reactions`/`my_vote` shape as post detail (§5/§6), so a
  /// card can show the score and the caller's own vote without opening the
  /// post. [myVote] is `1`, `-1`, or `0` (always `0` for anonymous callers).
  final PostReactions reactions;
  final int myVote;

  bool get isReviewed => reviewStatus == 'reviewed';

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final created = json['created_at'];
    final reactions = json['reactions'];
    return FeedPost(
      postId: '${json['post_id']}',
      title: (json['title'] as String?) ?? '',
      redactedExcerpt: (json['redacted_excerpt'] as String?) ?? '',
      category: cat is Map<String, dynamic> ? ScamCategory.fromJson(cat) : null,
      tags: _tags(json['tags']),
      reviewStatus: (json['review_status'] as String?) ?? 'unverified',
      createdAt: created is String ? DateTime.tryParse(created) : null,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      reactions: reactions is Map<String, dynamic>
          ? PostReactions.fromJson(reactions)
          : const PostReactions(up: 0, down: 0),
      myVote: (json['my_vote'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns a copy with the vote fields replaced. Used to update a single
  /// card in place after the user votes, without refetching the whole list.
  FeedPost copyWithVote({required PostReactions reactions, required int myVote}) {
    return FeedPost(
      postId: postId,
      title: title,
      redactedExcerpt: redactedExcerpt,
      category: category,
      tags: tags,
      reviewStatus: reviewStatus,
      createdAt: createdAt,
      commentCount: commentCount,
      reactions: reactions,
      myVote: myVote,
    );
  }

  static List<ScamTag> _tags(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ScamTag.fromJson)
        .toList(growable: false);
  }
}

class PostDetail {
  const PostDetail({
    required this.postId,
    required this.title,
    required this.redactedText,
    required this.category,
    required this.tags,
    required this.reviewStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    required this.reactions,
    required this.myVote,
    this.imageUrls = const [],
  });

  final String postId;
  final String title;
  final String redactedText;
  final ScamCategory? category;
  final List<ScamTag> tags;
  final String reviewStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int commentCount;
  final PostReactions reactions;
  final int myVote;

  /// Absolute URLs for the post's redacted screenshot derivatives. Loading
  /// them is owner-only, so pass [ApiClient.authHeaders] to `Image.network`.
  final List<String> imageUrls;

  bool get isReviewed => reviewStatus == 'reviewed';

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final created = json['created_at'];
    final updated = json['updated_at'];
    final reactions = json['reactions'];
    return PostDetail(
      postId: '${json['post_id']}',
      title: (json['title'] as String?) ?? '',
      redactedText: (json['redacted_text'] as String?) ?? '',
      category: cat is Map<String, dynamic> ? ScamCategory.fromJson(cat) : null,
      tags: FeedPost._tags(json['tags']),
      reviewStatus: (json['review_status'] as String?) ?? 'unverified',
      createdAt: created is String ? DateTime.tryParse(created) : null,
      updatedAt: updated is String ? DateTime.tryParse(updated) : null,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      reactions: reactions is Map<String, dynamic>
          ? PostReactions.fromJson(reactions)
          : const PostReactions(up: 0, down: 0),
      myVote: (json['my_vote'] as num?)?.toInt() ?? 0,
      imageUrls: _images(json['redacted_image_urls']),
    );
  }

  /// Reads `redacted_image_urls` (server-relative paths such as
  /// `/api/v1/community/posts/12/images/0`) and resolves each to an absolute
  /// URL. Only the redacted derivatives are ever served; the raw upload is
  /// never exposed. These endpoints are owner-only, so loading them needs the
  /// bearer token (see [ApiClient.authHeaders]).
  static List<String> _images(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map(ApiConfig.absoluteUrl)
        .toList(growable: false);
  }
}

class ReactionResult {
  const ReactionResult({
    required this.upCount,
    required this.downCount,
    required this.myVote,
  });

  final int upCount;
  final int downCount;
  final int myVote;

  factory ReactionResult.fromJson(Map<String, dynamic> json) {
    return ReactionResult(
      upCount: (json['up_count'] as num?)?.toInt() ?? 0,
      downCount: (json['down_count'] as num?)?.toInt() ?? 0,
      myVote: (json['my_vote'] as num?)?.toInt() ?? 0,
    );
  }
}

class PostComment {
  const PostComment({
    required this.commentId,
    this.parentId,
    required this.authorId,
    required this.authorLabel,
    this.isBot = false,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String commentId;
  final String? parentId;
  final String authorId;
  final String authorLabel;

  /// Whether this comment was written by the service's AI helper (summoned
  /// with `@help`) rather than a human author. Clients can surface an "AI"
  /// badge for it.
  final bool isBot;
  final String body;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isReply => (parentId ?? '').isNotEmpty;

  /// Name shown in the UI. The backend labels the bot "Grok"; the app shows it
  /// as [botDisplayName].
  String get displayLabel => isBot ? botDisplayName : authorLabel;

  static const String botDisplayName = 'NegevAI';

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final parent = json['parent_id'];
    final created = json['created_at'];
    final updated = json['updated_at'];
    return PostComment(
      commentId: '${json['comment_id']}',
      parentId: parent == null ? null : '$parent',
      authorId: '${json['author_id']}',
      authorLabel: (json['author_label'] as String?) ?? 'removed user',
      isBot: json['is_bot'] == true,
      body: (json['body'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'visible',
      createdAt: created is String ? DateTime.tryParse(created) : null,
      updatedAt: updated is String ? DateTime.tryParse(updated) : null,
    );
  }
}

class FlagResult {
  const FlagResult({required this.flagId, required this.status});

  final String flagId;
  final String status;

  factory FlagResult.fromJson(Map<String, dynamic> json) {
    return FlagResult(
      flagId: '${json['flag_id']}',
      status: (json['status'] as String?) ?? 'open',
    );
  }
}

String _humanize(String key) {
  final lastDot = key.lastIndexOf('.');
  final tail = lastDot >= 0 ? key.substring(lastDot + 1) : key;
  final words = tail.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (words.isEmpty) return key;
  return words
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
