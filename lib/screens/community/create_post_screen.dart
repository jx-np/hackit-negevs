import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.client,
    this.checkId,
    this.initialText,
  });

  final ApiClient client;
  final String? checkId;
  final String? initialText;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final CommunityService _community = CommunityService(widget.client);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _textController =
      TextEditingController(text: widget.initialText ?? '');

  List<ScamCategory> _categories = const [];
  List<ScamTag> _availableTags = const [];
  final Set<String> _selectedTags = <String>{};
  String? _scamType;

  bool _loadingOptions = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    List<ScamCategory> cats = const [];
    List<ScamTag> tags = const [];
    try {
      final types = await _community.scamTypes();
      cats = types.items;
    } catch (_) {}
    try {
      final tagList = await _community.tags(limit: 50);
      tags = tagList.items;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _availableTags = tags;
      _loadingOptions = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scamType == null) {
      setState(() => _error = AppLocalizations.of(context).createChooseType);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final post = await _community.createPost(
        checkId: widget.checkId,
        title: _titleController.text.trim(),
        redactedText: _textController.text.trim(),
        scamType: _scamType!,
        tags: _selectedTags.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(post);
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
      title: l10n.communityShareScam,
      scrollable: true,
      bottomBar: SizedBox(
        height: 60,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.send, size: 24),
          label: Text(
            _submitting ? l10n.commonSharing : l10n.commonShareWithCommunity,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.commonShareIntro, style: theme.textTheme.bodyLarge),
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
                  SizedBox(height: tokens.space.xl),
                  _FieldLabel(l10n.commonWhatKindOfScam),
                  SizedBox(height: tokens.space.md),
                  Wrap(
                    spacing: tokens.space.md,
                    runSpacing: tokens.space.md,
                    children: [
                      for (final cat in _categories)
                        ChoiceChip(
                          label: Text(cat.displayName, style: theme.textTheme.bodyLarge),
                          selected: _scamType == cat.slug,
                          onSelected: (_) => setState(() => _scamType = cat.slug),
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.space.lg,
                            vertical: tokens.space.md,
                          ),
                        ),
                    ],
                  ),
                  if (_availableTags.isNotEmpty) ...[
                    SizedBox(height: tokens.space.xl),
                    _FieldLabel(l10n.commonTagsOptional),
                    SizedBox(height: tokens.space.md),
                    Wrap(
                      spacing: tokens.space.md,
                      runSpacing: tokens.space.md,
                      children: [
                        for (final tag in _availableTags)
                          FilterChip(
                            label: Text(tag.displayName, style: theme.textTheme.bodyLarge),
                            selected: _selectedTags.contains(tag.slug),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _selectedTags.add(tag.slug);
                              } else {
                                _selectedTags.remove(tag.slug);
                              }
                            }),
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.space.lg,
                              vertical: tokens.space.md,
                            ),
                          ),
                      ],
                    ),
                  ],
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
