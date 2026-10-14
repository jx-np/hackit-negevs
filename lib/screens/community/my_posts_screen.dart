import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_screen.dart';
import '../../widgets/ui/empty_state.dart';
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
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      title: l10n.myPostsTitle,
      scrollable: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsets.only(
        top: tokens.space.sm,
        bottom: tokens.space.xl2,
      ),
      children: [
        if (_error != null) ...[
          _errorCard(),
          SizedBox(height: tokens.space.md),
        ],
        if (_posts.isEmpty && _error == null) _emptyCard(l10n),
        for (var index = 0; index < _posts.length; index++) ...[
          if (index > 0) SizedBox(height: tokens.space.md),
          _postCard(l10n, _posts[index]),
        ],
      ],
    );
  }

  Widget _postCard(AppLocalizations l10n, FeedPost post) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppCard(
      onTap: () => _openPost(post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (post.isReviewed) ...[
                SizedBox(width: tokens.space.sm),
                _reviewedBadge(l10n),
              ],
            ],
          ),
          SizedBox(height: tokens.space.sm),
          Text(
            post.redactedExcerpt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.space.md),
          Row(
            children: [
              Icon(
                LucideIcons.messageCircle,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: tokens.space.xs),
              Text(
                '${post.commentCount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _deletePost(post),
                icon: const Icon(LucideIcons.trash2, size: 20),
                label: Text(l10n.myPostsDelete),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.space.md,
                    vertical: tokens.space.sm,
                  ),
                  textStyle: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewedBadge(AppLocalizations l10n) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space.sm,
        vertical: tokens.space.xs,
      ),
      decoration: BoxDecoration(
        color: tokens.risk.safeContainer,
        borderRadius: tokens.radii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.badgeCheck, size: 18, color: tokens.risk.safe),
          SizedBox(width: tokens.space.xs),
          Text(
            l10n.commonReviewed,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: tokens.risk.onSafeContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(AppLocalizations l10n) {
    return AppCard(
      child: EmptyState(
        icon: LucideIcons.messageSquarePlus,
        title: l10n.commonNoPostsYet,
        message: l10n.myPostsNoneBody,
      ),
    );
  }

  Widget _errorCard() {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppCard(
      color: tokens.risk.dangerContainer,
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, color: tokens.risk.danger),
          SizedBox(width: tokens.space.md),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: tokens.risk.onDangerContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
