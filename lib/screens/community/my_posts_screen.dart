import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import 'post_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late final CommunityService _community = CommunityService(widget.client);

  bool _loading = true;
  String? _error;
  List<FeedPost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _community.myPosts();
      if (!mounted) return;
      setState(() {
        _posts = page.items;
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

  Future<void> _openPost(FeedPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PostDetailScreen(client: widget.client, postId: post.postId),
      ),
    );
    await _load();
  }

  Future<void> _deletePost(FeedPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myPostsDeleteConfirm),
        content: Text(l10n.myPostsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel, style: const TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.myPostsDelete,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _community.deletePost(post.postId);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPostsTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme, l10n),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) _errorCard(theme),
        if (_posts.isEmpty && _error == null) _emptyCard(theme, l10n),
        for (final post in _posts) _postCard(theme, l10n, post),
      ],
    );
  }

  Widget _postCard(ThemeData theme, AppLocalizations l10n, FeedPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPost(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (post.isReviewed) _reviewedBadge(theme, l10n),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 26),
                    tooltip: l10n.myPostsDelete,
                    color: theme.colorScheme.error,
                    onPressed: () => _deletePost(post),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(post.redactedExcerpt, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 20, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text('${post.commentCount}',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewedBadge(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            l10n.commonReviewed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.post_add, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.commonNoPostsYet,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.myPostsNoneBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                size: 28, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
