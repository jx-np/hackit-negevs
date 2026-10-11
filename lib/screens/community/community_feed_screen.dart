import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late final CommunityService _community = CommunityService(widget.client);

  bool _loading = true;
  String? _error;
  List<FeedPost> _posts = const [];
  List<ScamCategory> _categories = const [];
  String? _activeType;

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
      final feed = await _community.feed(scamType: _activeType);
      List<ScamCategory> cats = _categories;
      if (cats.isEmpty) {
        try {
          final types = await _community.scamTypes();
          cats = types.items;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _posts = feed.items;
        _categories = cats;
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

  Future<void> _selectType(String? slug) async {
    setState(() => _activeType = slug);
    await _load();
  }

  Future<void> _openPost(FeedPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(client: widget.client, postId: post.postId),
      ),
    );
    await _load();
  }

  Future<void> _createPost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreatePostScreen(client: widget.client),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Share a scam',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_categories.isNotEmpty) _filterChips(theme),
        if (_error != null) _errorCard(theme),
        if (_posts.isEmpty && _error == null) _emptyCard(theme),
        for (final post in _posts) _postCard(theme, post),
      ],
    );
  }

  Widget _filterChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('All'),
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            selected: _activeType == null,
            onSelected: (_) => _selectType(null),
          ),
          for (final cat in _categories)
            ChoiceChip(
              label: Text(cat.displayName),
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              selected: _activeType == cat.slug,
              onSelected: (_) => _selectType(cat.slug),
            ),
        ],
      ),
    );
  }

  Widget _postCard(ThemeData theme, FeedPost post) {
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
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (post.isReviewed) _reviewedBadge(theme),
                ],
              ),
              const SizedBox(height: 8),
              Text(post.redactedExcerpt, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (post.category != null) ...[
                    Icon(Icons.label_outline, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(post.category!.displayName, style: theme.textTheme.bodyMedium),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.chat_bubble_outline, size: 20, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text('${post.commentCount}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewedBadge(ThemeData theme) {
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
            'Reviewed',
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

  Widget _emptyCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.forum_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Scam reports shared by the community will show up here.',
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
            Icon(Icons.error_outline, size: 28, color: theme.colorScheme.error),
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
