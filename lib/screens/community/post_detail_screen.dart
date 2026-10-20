import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import '../../services/api/discussion_service.dart';
import '../../state/auth_controller.dart';
import '../../services/protection_settings.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/tour/coach_mark_overlay.dart';
import '../../widgets/tour/tour_controller.dart';
import '../../widgets/tour/tour_models.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_screen.dart';

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
  final TextEditingController _editController = TextEditingController();

  bool _loading = true;
  String? _error;
  PostDetail? _post;
  Map<String, String> _imageHeaders = const {};
  List<PostComment> _comments = const [];
  bool _postingComment = false;
  bool _voting = false;
  String? _replyParentId;
  String? _replyParentLabel;
  String? _editingCommentId;
  bool _savingEdit = false;

  static const String _helpHandle = 'help';
  static final RegExp _mentionAtCursor = RegExp(r'(?:^|\s)@(\w*)$');
  final FocusNode _commentFocus = FocusNode();
  String? _mentionQuery;

  StreamSubscription<SseEvent>? _eventsSub;
  Timer? _reconnectTimer;
  bool _hasBeenReady = false;

  /// Consecutive failed/closed connection attempts. Reset once the stream
  /// reaches `ready`. After [_maxReconnectAttempts] the live stream is left
  /// closed — the comment list still works via pull-to-refresh and manual
  /// actions, and a hard failure (deleted post, expired session) must not spin
  /// a request loop for as long as the screen happens to stay mounted.
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  static const Duration _reconnectBaseDelay = Duration(seconds: 3);
  String? _thinkingTriggerId;

  final ProtectionSettings _settings = ProtectionSettings();
  final CoachMarkTargets _tourTargets = CoachMarkTargets(0);
  late final TourController _tour = TourController(
    steps: kPostTourSteps,
    settings: _settings,
    readSeen: _settings.seenPostTour,
    writeSeen: () => _settings.setSeenPostTour(true),
  );
  bool _tourChecked = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onCommentChanged);
    _tour.addListener(_onTourChanged);
    _load();
    _connectEvents();
  }

  void _onTourChanged() {
    if (mounted) setState(() {});
  }

  /// Offers the post tour once, the first time a post finishes loading.
  Future<void> _maybeStartTour() async {
    if (_tourChecked) return;
    _tourChecked = true;
    final shouldStart = await _tour.shouldAutoStart();
    if (!shouldStart || !mounted || _post == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tour.start();
    });
  }

  @override
  void dispose() {
    _tour.removeListener(_onTourChanged);
    _tour.dispose();
    _reconnectTimer?.cancel();
    _eventsSub?.cancel();
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    _commentFocus.dispose();
    _editController.dispose();
    super.dispose();
  }

  String? get _currentUserId => context.read<AuthController>().user?.id;

  Future<List<PostComment>> _fetchComments() async {
    final comments = <PostComment>[];
    String? cursor;
    do {
      final page = await _discussion.comments(
        postId: widget.postId,
        limit: 100,
        cursor: cursor,
      );
      comments.addAll(page.items);
      cursor = page.hasMore ? page.nextCursor : null;
    } while (cursor != null);
    return comments;
  }

  /// Re-reads the comment list without the full-screen spinner. Used to fill
  /// any gap after the live stream reconnects.
  Future<void> _refreshComments() async {
    try {
      final comments = await _fetchComments();
      if (!mounted) return;
      setState(() => _comments = comments);
    } on ApiException {
      // Keep what is on screen; the next event or manual action retries.
    }
  }

  void _connectEvents() {
    _reconnectTimer?.cancel();
    _eventsSub?.cancel();
    _eventsSub = _discussion.events(widget.postId).listen(
      _onEvent,
      onError: (Object _) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts += 1;
    if (_reconnectAttempts > _maxReconnectAttempts) return;
    // Exponential backoff: 3s, 6s, 12s, 24s, 48s, 96s.
    final delay = _reconnectBaseDelay * (1 << (_reconnectAttempts - 1));
    _reconnectTimer = Timer(delay, () {
      if (mounted) _connectEvents();
    });
  }

  void _onEvent(SseEvent event) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(event.data);
      if (decoded is! Map<String, dynamic>) return;
      data = decoded;
    } catch (_) {
      return;
    }
    switch (event.event) {
      case 'ready':
        final reconnected = _hasBeenReady;
        _hasBeenReady = true;
        // A healthy stream means the failure counter starts over.
        _reconnectAttempts = 0;
        if (reconnected) {
          if (_thinkingTriggerId != null) {
            setState(() => _thinkingTriggerId = null);
          }
          _refreshComments();
        }
      case 'comment_created':
        _mergeComment(PostComment.fromJson(data));
      case 'help_thinking' || 'grok_thinking':
        setState(() => _thinkingTriggerId = '${data['trigger_comment_id']}');
      case 'help_replied' || 'grok_replied':
        final comment = data['comment'];
        setState(() => _thinkingTriggerId = null);
        if (comment is Map<String, dynamic>) {
          _mergeComment(PostComment.fromJson(comment));
        } else {
          _refreshComments();
        }
      case 'help_failed' || 'grok_failed':
        setState(() => _thinkingTriggerId = null);
    }
  }

  /// Adds [comment] to the thread unless it is already there (a bot reply is
  /// announced by both `comment_created` and `grok_replied`).
  void _mergeComment(PostComment comment) {
    if (!mounted || comment.status == 'removed') return;
    if (_comments.any((c) => c.commentId == comment.commentId)) return;
    setState(() => _comments = [..._comments, comment]);
  }

  void _onCommentChanged() {
    final value = _commentController.value;
    String? query;
    final selection = value.selection;
    if (selection.isValid && selection.isCollapsed && selection.baseOffset <= value.text.length) {
      final before = value.text.substring(0, selection.baseOffset);
      query = _mentionAtCursor.firstMatch(before)?.group(1);
    }
    if (query != _mentionQuery) setState(() => _mentionQuery = query);
  }

  void _applyMention(String handle) {
    final value = _commentController.value;
    final cursor = value.selection.baseOffset;
    if (cursor < 0 || cursor > value.text.length) return;
    final before = value.text.substring(0, cursor);
    final match = RegExp(r'@\w*$').firstMatch(before);
    if (match == null) return;
    final insert = '@$handle ';
    _commentController.value = TextEditingValue(
      text: before.substring(0, match.start) + insert + value.text.substring(cursor),
      selection: TextSelection.collapsed(offset: match.start + insert.length),
    );
    _commentFocus.requestFocus();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await _community.post(widget.postId);
      final imageHeaders = post.imageUrls.isEmpty
          ? const <String, String>{}
          : await widget.client.authHeaders();
      final comments = await _fetchComments();
      if (!mounted) return;
      setState(() {
        _post = post;
        _imageHeaders = imageHeaders;
        _comments = comments;
        _loading = false;
      });
      unawaited(_maybeStartTour());
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
          imageUrls: post.imageUrls,
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
      final created = await _discussion.addComment(
        postId: widget.postId,
        body: body,
        parentId: _replyParentId,
      );
      _commentController.clear();
      _replyParentId = null;
      _replyParentLabel = null;
      _mergeComment(created);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _postingComment = false);
    }
  }

  void _startReply(PostComment comment) {
    setState(() {
      _editingCommentId = null;
      _replyParentId = comment.parentId?.isNotEmpty == true ? comment.parentId : comment.commentId;
      _replyParentLabel = comment.displayLabel;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyParentId = null;
      _replyParentLabel = null;
    });
  }

  void _startEdit(PostComment comment) {
    setState(() {
      _replyParentId = null;
      _replyParentLabel = null;
      _editingCommentId = comment.commentId;
      _editController.text = comment.body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(PostComment comment) async {
    final body = _editController.text.trim();
    if (body.isEmpty || _savingEdit) return;
    setState(() => _savingEdit = true);
    try {
      await _discussion.editComment(commentId: comment.commentId, body: body);
      _editingCommentId = null;
      _editController.clear();
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _savingEdit = false);
    }
  }

  Future<void> _deleteComment(PostComment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.postDetailDeleteConfirm),
        content: Text(l10n.postDetailDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.postDetailCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.postDetailDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _discussion.deleteComment(comment.commentId);
      await _load();
    } on ApiException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _flagComment(PostComment comment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _FlagDialog(),
    );
    if (reason == null) return;
    try {
      await _discussion.flagComment(commentId: comment.commentId, reason: reason);
      if (!mounted) return;
      _showMessage(AppLocalizations.of(context).postDetailThankYou);
    } on ApiException catch (e) {
      _showMessage(e.message);
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
      if (!mounted) return;
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
    final l10n = AppLocalizations.of(context);
    return CoachMarkOverlay(
      controller: _tour,
      targets: _tourTargets,
      child: AppScreen(
        title: l10n.postDetailTitle,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.flag),
            tooltip: l10n.postDetailReportTooltip,
            onPressed: _post == null ? null : _flagPost,
          ),
        ],
        scrollable: false,
        body: _buildBody(Theme.of(context), l10n),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: AppCard(
          color: context.tokens.risk.dangerContainer,
          child: Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: context.tokens.risk.onDangerContainer)),
        ),
      );
    }
    final post = _post!;
    final byId = <String, PostComment>{for (final c in _comments) c.commentId: c};
    final roots = <PostComment>[];
    final descendantsByRoot = <String, List<PostComment>>{};
    for (final comment in _comments) {
      final parentId = comment.parentId;
      final isRoot = parentId == null || parentId.isEmpty || !byId.containsKey(parentId);
      if (isRoot) {
        roots.add(comment);
      } else {
        final rootId = _resolveRootId(comment, byId);
        descendantsByRoot.putIfAbsent(rootId, () => <PostComment>[]).add(comment);
      }
    }
    final userId = _currentUserId;
    final tokens = context.tokens;
    return ListView(
      // Build every row while the tour runs so its targets are mounted even
      // when they start off screen.
      scrollCacheExtent:
          _tour.active ? const ScrollCacheExtent.pixels(double.infinity) : null,
      padding: EdgeInsets.only(top: tokens.space.sm, bottom: tokens.space.xl2),
      children: [
        Text(post.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (post.imageUrls.isNotEmpty) ...[
          SizedBox(height: tokens.space.md),
          _pictureStrip(theme, post.imageUrls),
        ],
        SizedBox(height: tokens.space.md),
        Text(post.redactedText, style: theme.textTheme.bodyLarge),
        SizedBox(height: tokens.space.xl),
        _voteRow(theme, post),
        SizedBox(height: tokens.space.xl),
        Text(
          l10n.postDetailComments(_comments.length),
          key: _tourTargets.keyFor(TourTarget.postComments),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: tokens.space.md),
        if (_comments.isEmpty)
          Text(l10n.postDetailNoComments, style: theme.textTheme.bodyLarge)
        else
          for (final root in roots)
            _commentThread(theme, l10n, root, descendantsByRoot[root.commentId] ?? const [], userId),
        SizedBox(height: tokens.space.lg),
        _commentComposer(theme, l10n),
      ],
    );
  }

  Widget _pictureStrip(ThemeData theme, List<String> images) {
    final tokens = context.tokens;
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
         separatorBuilder: (_, _) => SizedBox(width: tokens.space.md),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(images, index),
            child: ClipRRect(
               borderRadius: tokens.radii.lgRadius,
              child: Image.network(
                images[index],
                headers: _imageHeaders.isEmpty ? null : _imageHeaders,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 160,
                  height: 160,
                  color: theme.colorScheme.surfaceContainerHighest,
                   child: Icon(LucideIcons.imageOff, size: 40, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Opens a full-screen, pinch-to-zoom viewer starting at [initialIndex].
  void _openImageViewer(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ImageViewer(
          images: images,
          initialIndex: initialIndex,
          headers: _imageHeaders.isEmpty ? null : _imageHeaders,
        ),
      ),
    );
  }

  String _resolveRootId(PostComment comment, Map<String, PostComment> byId) {
    var current = comment;
    final seen = <String>{current.commentId};
    while (true) {
      final parentId = current.parentId;
      if (parentId == null || parentId.isEmpty) return current.commentId;
      final parent = byId[parentId];
      if (parent == null) return current.commentId;
      if (!seen.add(parent.commentId)) return current.commentId;
      current = parent;
    }
  }

  Widget _commentThread(
    ThemeData theme,
    AppLocalizations l10n,
    PostComment root,
    List<PostComment> replies,
    String? userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _commentCard(theme, l10n, root, userId, isReply: false),
        if (replies.isNotEmpty)
          Padding(
             padding: EdgeInsets.only(left: context.tokens.space.md),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.colorScheme.outlineVariant, width: 2),
                ),
              ),
               padding: EdgeInsets.only(left: context.tokens.space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in replies)
                    _commentCard(theme, l10n, reply, userId, isReply: true),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _voteRow(ThemeData theme, PostDetail post) {
    return Row(
      children: [
         _voteButton(
          theme,
          icon: LucideIcons.thumbsUp,
          label: '${post.reactions.up}',
          active: post.myVote == 1,
          onTap: () => _vote(1),
        ),
         SizedBox(width: context.tokens.space.md),
        _voteButton(
          theme,
          icon: LucideIcons.thumbsDown,
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
      child: OutlinedButton.icon(
        onPressed: _voting ? null : onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
           backgroundColor: active ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
          foregroundColor: active ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _commentCard(
    ThemeData theme,
    AppLocalizations l10n,
    PostComment comment,
    String? userId, {
    required bool isReply,
  }) {
    final isRemoved = comment.status == 'removed';
    final isAuthor = userId != null && userId == comment.authorId;
    final isEditing = _editingCommentId == comment.commentId;
    final wasEdited = comment.updatedAt != null &&
        comment.createdAt != null &&
        comment.updatedAt!.isAfter(comment.createdAt!);
    return Padding(
      padding: EdgeInsets.only(bottom: context.tokens.space.md),
      child: AppCard(
        padding: EdgeInsets.all(context.tokens.space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    comment.displayLabel,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (comment.isBot) ...[
                  SizedBox(width: context.tokens.space.xs),
                  _aiBadge(theme, l10n),
                ],
                const Spacer(),
                if (wasEdited && !isRemoved)
                  Text(
                    l10n.postDetailEdited,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            SizedBox(height: context.tokens.space.sm),
            if (isRemoved)
              Text(
                l10n.postDetailRemovedComment,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (isEditing)
              _editField(theme, l10n, comment)
            else
              Text(comment.body, style: theme.textTheme.bodyLarge, softWrap: true),
            if (!isRemoved && !isEditing)
              _commentActions(theme, l10n, comment, isAuthor),
          ],
        ),
      ),
    );
  }

  Widget _aiBadge(ThemeData theme, AppLocalizations l10n) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tokens.space.sm, vertical: tokens.space.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: tokens.radii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.sparkles, size: 14, color: theme.colorScheme.onSecondaryContainer),
          SizedBox(width: tokens.space.xs),
          Text(
            l10n.postDetailAiBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(ThemeData theme, AppLocalizations l10n, PostComment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _editController,
          minLines: 2,
          maxLines: 6,
          autofocus: true,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            filled: true,
             border: OutlineInputBorder(borderRadius: context.tokens.radii.mdRadius),
             contentPadding: EdgeInsets.symmetric(horizontal: context.tokens.space.lg, vertical: context.tokens.space.md),
          ),
        ),
         SizedBox(height: context.tokens.space.sm),
        Wrap(
          alignment: WrapAlignment.end,
          runSpacing: context.tokens.space.xs,
          children: [
            TextButton(
              onPressed: _savingEdit ? null : _cancelEdit,
              child: Text(l10n.postDetailCancel),
            ),
             SizedBox(width: context.tokens.space.xs),
            FilledButton(
              onPressed: _savingEdit ? null : () => _saveEdit(comment),
              child: _savingEdit
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.postDetailSave),
            ),
          ],
        ),
      ],
    );
  }

  Widget _commentActions(ThemeData theme, AppLocalizations l10n, PostComment comment, bool isAuthor) {
    final buttonStyle = TextButton.styleFrom(
       padding: EdgeInsets.symmetric(horizontal: context.tokens.space.sm, vertical: context.tokens.space.xs),
       minimumSize: const Size(48, 48),
      foregroundColor: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
       padding: EdgeInsets.only(top: context.tokens.space.xs),
      child: Wrap(
        spacing: 4,
        children: [
          TextButton.icon(
            style: buttonStyle,
            onPressed: () => _startReply(comment),
             icon: const Icon(LucideIcons.reply, size: 18),
            label: Text(l10n.postDetailReply),
          ),
          if (isAuthor)
            TextButton.icon(
              style: buttonStyle,
              onPressed: () => _startEdit(comment),
               icon: const Icon(LucideIcons.pencil, size: 18),
              label: Text(l10n.postDetailEdit),
            ),
          if (isAuthor)
            TextButton.icon(
              style: buttonStyle,
              onPressed: () => _deleteComment(comment),
               icon: Icon(LucideIcons.trash2, size: 18, color: theme.colorScheme.error),
              label: Text(l10n.postDetailDelete),
            ),
          if (!isAuthor)
            TextButton.icon(
              style: buttonStyle,
              onPressed: () => _flagComment(comment),
               icon: const Icon(LucideIcons.flag, size: 18),
              label: Text(l10n.postDetailReportTooltip),
            ),
        ],
      ),
    );
  }

  Widget _commentComposer(ThemeData theme, AppLocalizations l10n) {
    final replyingTo = _replyParentLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (replyingTo != null)
          Container(
             margin: EdgeInsets.only(bottom: context.tokens.space.sm),
             padding: EdgeInsets.fromLTRB(context.tokens.space.md, context.tokens.space.sm, context.tokens.space.sm, context.tokens.space.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
               borderRadius: context.tokens.radii.mdRadius,
            ),
            child: Row(
              children: [
                 Icon(LucideIcons.reply, size: 18, color: theme.colorScheme.onSurfaceVariant),
                 SizedBox(width: context.tokens.space.sm),
                Expanded(
                  child: Text(
                    l10n.postDetailReplying(replyingTo),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                   icon: const Icon(LucideIcons.x, size: 20),
                  tooltip: l10n.postDetailCancel,
                  onPressed: _cancelReply,
                ),
              ],
            ),
          ),
        if (_thinkingTriggerId != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.tokens.space.sm),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: context.tokens.space.sm),
                Text(
                  l10n.postDetailBotThinking,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        if (_mentionQuery != null && _helpHandle.startsWith(_mentionQuery!.toLowerCase()))
          Container(
            margin: EdgeInsets.only(bottom: context.tokens.space.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: context.tokens.radii.mdRadius,
            ),
            child: ListTile(
              leading: Icon(LucideIcons.sparkles, color: theme.colorScheme.primary),
              title: Text('@$_helpHandle', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text(l10n.postDetailMentionHelpHint),
              onTap: () => _applyMention(_helpHandle),
            ),
          ),
        TextField(
          key: _tourTargets.keyFor(TourTarget.postCommentField),
          controller: _commentController,
          focusNode: _commentFocus,
          minLines: 2,
          maxLines: 5,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: replyingTo != null ? l10n.postDetailWriteReply : l10n.postDetailWriteComment,
            filled: true,
             border: OutlineInputBorder(borderRadius: context.tokens.radii.mdRadius),
             contentPadding: EdgeInsets.symmetric(horizontal: context.tokens.space.lg, vertical: context.tokens.space.md),
          ),
        ),
         SizedBox(height: context.tokens.space.md),
        SizedBox(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: _postingComment ? null : _addComment,
            icon: _postingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                 : const Icon(LucideIcons.send),
            label: Text(l10n.postDetailPostComment, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
          child: Text(l10n.commonCancel, style: theme.textTheme.bodyMedium),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason),
          child: Text(l10n.commonReport, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Full-screen, pinch-to-zoom image viewer. Swipe horizontally to move between
/// a post's images; tap the close button (or system back) to dismiss. Loads the
/// owner-only redacted images with the caller's auth [headers].
class _ImageViewer extends StatefulWidget {
  const _ImageViewer({
    required this.images,
    required this.initialIndex,
    this.headers,
  });

  final List<String> images;
  final int initialIndex;
  final Map<String, String>? headers;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.images.length > 1;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: AppLocalizations.of(context).commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: multiple
            ? Text('${_index + 1} / ${widget.images.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.network(
                widget.images[index],
                headers: widget.headers,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(LucideIcons.imageOff, size: 64, color: Colors.white54),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
