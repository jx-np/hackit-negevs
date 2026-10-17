import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_screen.dart';

/// Edit an existing post's title and message.
///
/// The backend `PATCH /community/posts/{id}` accepts only title and
/// redacted_text — not the scam type — so this screen omits the category
/// chooser that [CreatePostScreen] has. Editing the message re-scrubs it and
/// sends the post back to moderation (`review_status` returns to
/// `unverified`), which is why the screen warns the user before saving.
///
/// Pops with the updated [PostDetail] on success so the caller can refresh.
class EditPostScreen extends StatefulWidget {
  const EditPostScreen({
    super.key,
    required this.client,
    required this.post,
  });

  final ApiClient client;
  final PostDetail post;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final CommunityService _community = CommunityService(widget.client);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
      TextEditingController(text: widget.post.title);
  late final TextEditingController _textController =
      TextEditingController(text: widget.post.redactedText);

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await _community.updatePost(
        postId: widget.post.postId,
        title: _titleController.text.trim(),
        redactedText: _textController.text.trim(),
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.editPostSaved)));
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  String? _validateTitle(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).createAddTitle;
    }
    return null;
  }

  String? _validateText(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).createAddMessage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return AppScreen(
      title: l10n.editPostTitle,
      scrollable: true,
      bottomBar: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.check, size: 24),
          label: Text(
            _submitting ? l10n.editPostSaving : l10n.editPostSave,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(tokens.space.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: tokens.radii.mdRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: tokens.space.md),
                        Expanded(
                          child: Text(
                            l10n.editPostReReview,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.space.xl),
                  _FieldLabel(l10n.commonTitle),
                  SizedBox(height: tokens.space.sm),
                  TextFormField(
                    controller: _titleController,
                    validator: _validateTitle,
                    style: theme.textTheme.titleMedium,
                    decoration: _fieldDecoration(l10n.commonTitleHint),
                  ),
                  SizedBox(height: tokens.space.xl),
                  _FieldLabel(l10n.commonMessage),
                  SizedBox(height: tokens.space.sm),
                  TextFormField(
                    controller: _textController,
                    validator: _validateText,
                    minLines: 4,
                    maxLines: 10,
                    style: theme.textTheme.bodyLarge,
                    decoration: _fieldDecoration(l10n.commonMessageHint),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: tokens.space.lg),
                    Container(
                      padding: EdgeInsets.all(tokens.space.lg),
                      decoration: BoxDecoration(
                        color: tokens.risk.dangerContainer,
                        borderRadius: tokens.radii.mdRadius,
                      ),
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
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: context.tokens.radii.mdRadius,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.tokens.space.lg,
        vertical: 18,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
