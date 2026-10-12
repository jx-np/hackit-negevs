import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../models/api/community_models.dart';
import '../../services/api/community_service.dart';

class ReportTabScreen extends StatefulWidget {
  const ReportTabScreen({
    super.key,
    required this.client,
  });

  final ApiClient client;

  @override
  State<ReportTabScreen> createState() => _ReportTabScreenState();
}

class _ReportTabScreenState extends State<ReportTabScreen> {
  late final CommunityService _community = CommunityService(widget.client);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  List<ScamCategory> _categories = const [];
  List<ScamTag> _availableTags = const [];
  final Set<String> _selectedTags = <String>{};
  String? _scamType;

  bool _loadingOptions = true;
  bool _submitting = false;
  String? _error;
  bool _justShared = false;

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
      _justShared = false;
    });
    try {
      await _community.createPost(
        title: _titleController.text.trim(),
        redactedText: _textController.text.trim(),
        scamType: _scamType!,
        tags: _selectedTags.toList(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _justShared = true;
        _titleController.clear();
        _textController.clear();
        _selectedTags.clear();
        _scamType = null;
      });
      _formKey.currentState?.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reportTabThankYou)),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reportTabTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.commonShareIntro,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(l10n.commonTitle),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      validator: _validateTitle,
                      style: theme.textTheme.titleMedium,
                      decoration: _fieldDecoration(l10n.commonTitleHint),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(l10n.commonMessage),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _textController,
                      validator: _validateText,
                      minLines: 4,
                      maxLines: 10,
                      style: theme.textTheme.bodyLarge,
                      decoration: _fieldDecoration(l10n.commonMessageHint),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(l10n.commonWhatKindOfScam),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final cat in _categories)
                          ChoiceChip(
                            label: Text(
                              cat.displayName,
                              style: theme.textTheme.bodyLarge,
                            ),
                            selected: _scamType == cat.slug,
                            onSelected: (_) =>
                                setState(() => _scamType = cat.slug),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                      ],
                    ),
                    if (_availableTags.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _FieldLabel(l10n.commonTagsOptional),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final tag in _availableTags)
                            FilterChip(
                              label: Text(
                                tag.displayName,
                                style: theme.textTheme.bodyLarge,
                              ),
                              selected: _selectedTags.contains(tag.slug),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _selectedTags.add(tag.slug);
                                } else {
                                  _selectedTags.remove(tag.slug);
                                }
                              }),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (_justShared) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.reportTabTrackIt,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                            ),
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
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.publish, size: 26),
                        label: Text(
                          _submitting
                              ? l10n.commonSharing
                              : l10n.commonShareWithCommunity,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
