import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../services/api/community_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/app_screen.dart';

class ReportTabScreen extends StatefulWidget {
  const ReportTabScreen({
    super.key,
    required this.client,
    this.prefillTitle,
    this.prefillText,
    this.numberReport = false,
    this.prefillNumber,
  });

  final ApiClient client;
  final String? prefillTitle;
  final String? prefillText;
  final bool numberReport;
  final String? prefillNumber;

  @override
  State<ReportTabScreen> createState() => _ReportTabScreenState();
}

class _ReportTabScreenState extends State<ReportTabScreen> {
  static const int _maxImageBytes = 20 * 1024 * 1024;

  late final CommunityService _community = CommunityService(widget.client);
  final ImagePicker _imagePicker = ImagePicker();

  static const List<String> _reasons = <String>['spam', 'scam', 'other'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  String _reason = 'spam';

  final List<XFile> _images = <XFile>[];

  bool _submitting = false;
  String? _error;
  bool _justShared = false;

  @override
  void initState() {
    super.initState();
    final prefillTitle = widget.prefillTitle;
    final prefillText = widget.prefillText;
    final prefillNumber = widget.prefillNumber;
    if (prefillTitle != null) _titleController.text = prefillTitle;
    if (prefillText != null) _textController.text = prefillText;
    if (prefillNumber != null) _numberController.text = prefillNumber;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final List<XFile> picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;
    final List<XFile> accepted = <XFile>[];
    bool rejected = false;
    for (final XFile file in picked) {
      final int length = await file.length();
      if (length > _maxImageBytes) {
        rejected = true;
        continue;
      }
      accepted.add(file);
    }
    if (!mounted) return;
    setState(() {
      _images.addAll(accepted);
    });
    if (rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonImageTooLarge)),
      );
    }
  }

  void _removePhoto(XFile file) {
    setState(() {
      _images.remove(file);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _justShared = false;
    });
    try {
      if (widget.numberReport) {
        await _community.reportNumber(
          number: _numberController.text.trim(),
          reason: _reason,
        );
      } else {
        await _community.createPost(
          title: _titleController.text.trim(),
          redactedText: _textController.text.trim(),
        );
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _justShared = true;
        if (!widget.numberReport) {
          _titleController.clear();
          _textController.clear();
          _images.clear();
        }
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

  String? _validateNumber(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).createAddTitle;
    }
    return null;
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

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'spam':
        return 'Spam';
      case 'scam':
        return 'Scam';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return AppScreen(
      title: l10n.reportTabTitle,
      bottomBar: SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.send, size: 22),
          label: Text(
            _submitting ? l10n.commonSharing : l10n.commonShare,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.commonShareIntro, style: theme.textTheme.bodyLarge),
            SizedBox(height: tokens.space.xl),
            if (widget.numberReport) ...[
              _FieldLabel(l10n.commonTitle),
              SizedBox(height: tokens.space.sm),
              TextFormField(
                controller: _numberController,
                validator: _validateNumber,
                keyboardType: TextInputType.phone,
                style: theme.textTheme.titleMedium,
                decoration: _fieldDecoration(l10n.commonTitleHint),
              ),
              SizedBox(height: tokens.space.xl),
              _FieldLabel(l10n.commonMessage),
              SizedBox(height: tokens.space.md),
              _ReasonSelector(
                reasons: _reasons,
                selected: _reason,
                labelFor: _reasonLabel,
                enabled: !_submitting,
                onSelected: (value) => setState(() => _reason = value),
              ),
            ] else ...[
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
              _FieldLabel(l10n.commonPhotos),
              SizedBox(height: tokens.space.md),
              if (_images.isNotEmpty) ...[
                Wrap(
                  spacing: tokens.space.md,
                  runSpacing: tokens.space.md,
                  children: [
                    for (final XFile image in _images)
                      _PhotoThumbnail(
                        file: image,
                        onRemove: () => _removePhoto(image),
                        removeLabel: l10n.commonRemovePhoto,
                      ),
                  ],
                ),
                SizedBox(height: tokens.space.md),
              ],
              OutlinedButton.icon(
                onPressed: _submitting ? null : _addPhoto,
                icon: const Icon(LucideIcons.imagePlus, size: 22),
                label: Text(
                  l10n.commonAddPhoto,
                  style: const TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: tokens.space.lg),
                ),
              ),
            ],
            if (_justShared) ...[
              SizedBox(height: tokens.space.xl),
              _StatusNote(
                icon: LucideIcons.circleCheck,
                message: l10n.reportTabTrackIt,
                background: tokens.risk.safeContainer,
                foreground: tokens.risk.onSafeContainer,
                accent: tokens.risk.safe,
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: tokens.space.xl),
              _StatusNote(
                icon: LucideIcons.circleAlert,
                message: _error!,
                background: tokens.risk.dangerContainer,
                foreground: tokens.risk.onDangerContainer,
                accent: tokens.risk.danger,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}

class _ReasonSelector extends StatelessWidget {
  const _ReasonSelector({
    required this.reasons,
    required this.selected,
    required this.labelFor,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> reasons;
  final String selected;
  final String Function(String) labelFor;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final String reason in reasons) ...[
          AppCard(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.space.lg,
              vertical: tokens.space.sm,
            ),
            color: reason == selected
                ? scheme.primary.withValues(alpha: 0.08)
                : null,
            border: reason == selected
                ? Border.all(color: scheme.primary, width: 1.5)
                : Border.all(color: scheme.outlineVariant),
            onTap: enabled ? () => onSelected(reason) : null,
            child: Row(
              children: [
                Icon(
                  reason == selected
                      ? LucideIcons.circleDot
                      : LucideIcons.circle,
                  size: 22,
                  color: reason == selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                SizedBox(width: tokens.space.md),
                Text(
                  labelFor(reason),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: reason == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (reason != reasons.last) SizedBox(height: tokens.space.sm),
        ],
      ],
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
    required this.accent,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: tokens.radii.mdRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: accent),
          SizedBox(width: tokens.space.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.file,
    required this.onRemove,
    required this.removeLabel,
  });

  final XFile file;
  final VoidCallback onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: tokens.radii.mdRadius,
            child: Image.file(
              File(file.path),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: removeLabel,
                iconSize: 20,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: onRemove,
              ),
            ),
          ),
        ],
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
