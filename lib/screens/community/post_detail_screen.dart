import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import '../../services/api/discussion_service.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.client, required this.postId});

  final ApiClient client;
  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final CommunityService _community = CommunityService(widget.client);
  late final DiscussionService _discussion = DiscussionService(widget.client);
  final TextEditingController _commentController = TextEditingController();

  bool _loading = true;
  String? _error;
  PostDetail? _post;
  List<PostComment> _comments = const [];
  bool _postingComment = false;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await _community.post(widget.postId);
      List<PostComment> comments = const [];
      try {
        final page = await _discussion.comments(postId: widget.postId);
        comments = page.items;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _post = post;
        _comments = comments;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _vote(int vote) async {
    final post = _post;
    if (post == null || _voting) return;
    setState(() => _voting = true);
    try {
      final result = post.myVote == vote
          ? await _community.clearReaction(widget.postId)
          : await _community.setReaction(postId: widget.postId, vote: vote);
      if (!mounted) return;
      setState(() {
        _post = PostDetail(
          postId: post.postId,
          title: post.title,
          redactedText: post.redactedText,
          category: post.category,
          tags: post.tags,
          reviewStatus: post.reviewStatus,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          commentCount: post.commentCount,
          reactions: PostReactions(up: result.upCount, down: result.downCount),
          myVote: result.myVote,
        );
      });
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _addComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _postingComment) return;
    setState(() => _postingComment = true);
    try {
      await _discussion.addComment(postId: widget.postId, body: body);
      _commentController.clear();
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _postingComment = false);
    }
  }

  Future<void> _flagPost() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _FlagDialog(),
    );
    if (reason == null) return;
    try {
      await _community.flagPost(postId: widget.postId, reason: reason);
      _showMessage(AppLocalizations.of(context).postDetailThankYou);
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.postDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, size: 28),
            tooltip: l10n.postDetailReportTooltip,
            onPressed: _post == null ? null : _flagPost,
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ),
      );
    }
    final post = _post!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(post.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(post.redactedText, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        _voteRow(theme, post),
        const SizedBox(height: 20),
        Text(
          l10n.postDetailComments(_comments.length),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          Text(l10n.postDetailNoComments, style: theme.textTheme.bodyLarge)
        else
          for (final comment in _comments) _commentCard(theme, comment),
        const SizedBox(height: 16),
        _commentComposer(theme, l10n),
      ],
    );
  }

  Widget _voteRow(ThemeData theme, PostDetail post) {
    return Row(
      children: [
        _voteButton(
          theme,
          icon: Icons.thumb_up,
          label: '${post.reactions.up}',
          active: post.myVote == 1,
          onTap: () => _vote(1),
        ),
        const SizedBox(width: 12),
        _voteButton(
          theme,
          icon: Icons.thumb_down,
          label: '${post.reactions.down}',
          active: post.myVote == -1,
          onTap: () => _vote(-1),
        ),
      ],
    );
  }

  Widget _voteButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 56,
        child: OutlinedButton.icon(
          onPressed: _voting ? null : onTap,
          icon: Icon(icon, size: 24),
          label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            backgroundColor: active ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
            foregroundColor: active ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _commentCard(ThemeData theme, PostComment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.authorLabel,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(comment.body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _commentComposer(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _commentController,
          minLines: 2,
          maxLines: 5,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: l10n.postDetailWriteComment,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _postingComment ? null : _addComment,
            icon: _postingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(l10n.postDetailPostComment, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _FlagDialog extends StatefulWidget {
  @override
  State<_FlagDialog> createState() => _FlagDialogState();
}

class _FlagDialogState extends State<_FlagDialog> {
  String _reason = 'harmful';

  static const List<String> _reasonSlugs = [
    'personal_information',
    'harmful',
    'spam',
    'misinformation',
    'other',
  ];

  String _reasonLabel(AppLocalizations l10n, String slug) {
    switch (slug) {
      case 'personal_information':
        return l10n.postDetailFlagPersonalInfo;
      case 'harmful':
        return l10n.postDetailFlagHarmful;
      case 'spam':
        return l10n.postDetailFlagSpam;
      case 'misinformation':
        return l10n.postDetailFlagMisinfo;
      case 'other':
      default:
        return l10n.postDetailFlagOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        l10n.postDetailReportTooltip,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: RadioGroup<String>(
        groupValue: _reason,
        onChanged: (value) => setState(() => _reason = value ?? _reason),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final slug in _reasonSlugs)
              RadioListTile<String>(
                value: slug,
                title: Text(_reasonLabel(l10n, slug), style: theme.textTheme.bodyLarge),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel, style: const TextStyle(fontSize: 16)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason),
          child: Text(l10n.commonReport, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
