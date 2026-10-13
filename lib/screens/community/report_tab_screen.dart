import 'dart:io';

import 'package:flutter/material.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../services/api/community_service.dart';

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reportTabTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
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
              if (widget.numberReport) ...[
                _FieldLabel(l10n.commonTitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numberController,
                  validator: _validateNumber,
                  keyboardType: TextInputType.phone,
                  style: theme.textTheme.titleMedium,
                  decoration: _fieldDecoration(l10n.commonTitleHint),
                ),
                const SizedBox(height: 24),
                _FieldLabel(l10n.commonMessage),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _reason,
                  onChanged: (value) {
                    if (_submitting || value == null) return;
                    setState(() => _reason = value);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final String reason in _reasons)
                        RadioListTile<String>(
                          value: reason,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _reasonLabel(reason),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
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
                _FieldLabel(l10n.commonPhotos),
                const SizedBox(height: 12),
                if (_images.isNotEmpty) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final XFile image in _images)
                        _PhotoThumbnail(
                          file: image,
                          onRemove: () => _removePhoto(image),
                          removeLabel: l10n.commonRemovePhoto,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _addPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 24),
                  label: Text(
                    l10n.commonAddPhoto,
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
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
                    _submitting ? l10n.commonSharing : l10n.commonShare,
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
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
                icon: const Icon(Icons.close, color: Colors.white),
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
