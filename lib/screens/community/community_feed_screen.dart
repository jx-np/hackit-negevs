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
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return AppScreen(
      title: l10n.communityTitle,
      scrollable: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(theme, l10n),
      ),
      bottomBar: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _createPost,
          icon: const Icon(LucideIcons.plus),
          label: Text(l10n.communityShareScam),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: theme.textTheme.titleMedium,
            shape: RoundedRectangleBorder(borderRadius: tokens.radii.lgRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    final tokens = context.tokens;
    if (_loading && _posts.isEmpty) {
      // Keep the view scrollable so pull-to-refresh still works while the
      // first load is in flight or when the list is empty.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: tokens.space.sm, bottom: tokens.space.xl2),
      children: [
        if (_categories.isNotEmpty) _filterChips(theme, l10n),
        if (_error != null) _errorCard(theme),
        if (_posts.isEmpty && _error == null) _emptyCard(theme, l10n),
        for (final post in _posts) ...[
          SizedBox(height: tokens.space.md),
          _postCard(theme, l10n, post),
        ],
      ],
    );
  }

  Widget _filterChips(ThemeData theme, AppLocalizations l10n) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space.md),
      child: Wrap(
        spacing: tokens.space.sm,
        runSpacing: tokens.space.sm,
        children: [
          ChoiceChip(
            label: Text(l10n.communityAll),
            labelStyle: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            selected: _activeType == null,
            onSelected: (_) => _selectType(null),
          ),
          for (final cat in _categories)
            ChoiceChip(
              label: Text(cat.displayName),
              labelStyle: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              selected: _activeType == cat.slug,
              onSelected: (_) => _selectType(cat.slug),
            ),
        ],
      ),
    );
  }

  Widget _postCard(ThemeData theme, AppLocalizations l10n, FeedPost post) {
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (post.isReviewed) ...[
                SizedBox(width: tokens.space.sm),
                _reviewedBadge(theme, l10n),
              ],
            ],
          ),
          SizedBox(height: tokens.space.sm),
          Text(post.redactedExcerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
          SizedBox(height: tokens.space.md),
          Wrap(
            spacing: tokens.space.lg,
            runSpacing: tokens.space.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (post.category != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.tag, size: 20, color: scheme.primary),
                    SizedBox(width: tokens.space.xs),
                    Flexible(
                      child: Text(
                        post.category!.displayName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.messageCircle, size: 20, color: scheme.onSurfaceVariant),
                  SizedBox(width: tokens.space.xs),
                  Text('${post.commentCount}', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewedBadge(ThemeData theme, AppLocalizations l10n) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tokens.space.md, vertical: tokens.space.xs),
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
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.risk.onSafeContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(ThemeData theme, AppLocalizations l10n) {
    return AppCard(
      child: EmptyState(
        icon: LucideIcons.messagesSquare,
        title: l10n.commonNoPostsYet,
        message: l10n.communityNoPostsBody,
      ),
    );
  }

  Widget _errorCard(ThemeData theme) {
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
              style: theme.textTheme.bodyLarge?.copyWith(color: tokens.risk.onDangerContainer),
            ),
          ),
        ],
      ),
    );
  }
}
