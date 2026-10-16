import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/api/api_exception.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/services/api/community_service.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_card.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';

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
  String _reason = 'scam';

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

  Future<void> _pasteMessage() async {
    final l10n = AppLocalizations.of(context);
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final String text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportTabPasteEmpty)),
      );
      return;
    }
    _textController.text = text;
    _textController.selection =
        TextSelection.collapsed(offset: _textController.text.length);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
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
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  void _reportAnother() {
    setState(() {
      _justShared = false;
      _error = null;
      _reason = 'scam';
      _titleController.clear();
      _textController.clear();
      _numberController.clear();
      _images.clear();
    });
  }

  String? _validateNumber(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return AppLocalizations.of(context).reportTabNumberRequired;
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

  List<_ReasonOption> _reasonOptions(AppLocalizations l10n) {
    return <_ReasonOption>[
      for (final String reason in _reasons)
        switch (reason) {
          'spam' => _ReasonOption(
              value: reason,
              icon: LucideIcons.megaphone,
              label: l10n.reportSpam,
              description: l10n.reportTabReasonSpamBody,
            ),
          'scam' => _ReasonOption(
              value: reason,
              icon: LucideIcons.shieldAlert,
              label: l10n.reportScam,
              description: l10n.reportTabReasonScamBody,
            ),
          _ => _ReasonOption(
              value: reason,
              icon: LucideIcons.circleHelp,
              label: l10n.reportOther,
              description: l10n.reportTabReasonOtherBody,
            ),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_justShared) {
      final bool canPop = Navigator.of(context).canPop();
      return AppScreen(
        title: l10n.reportTabTitle,
        body: _SuccessView(
          message: widget.numberReport
              ? l10n.reportTabThankYou
              : l10n.reportTabTrackIt,
          reportAnotherLabel: l10n.reportTabReportAnother,
          onReportAnother: _reportAnother,
          doneLabel: l10n.reportTabDone,
          onDone: canPop ? () => Navigator.of(context).pop() : null,
        ),
      );
    }

    return AppScreen(
      title: l10n.reportTabTitle,
      bottomBar: _SubmitButton(
        submitting: _submitting,
        label: _submitting ? l10n.commonSharing : l10n.commonShare,
        onPressed: _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(
              icon: widget.numberReport
                  ? LucideIcons.phone
                  : LucideIcons.messageSquareWarning,
              title: widget.numberReport
                  ? l10n.reportTabNumberHeroTitle
                  : l10n.reportTabHeroTitle,
              body: widget.numberReport
                  ? l10n.reportTabNumberHeroBody
                  : l10n.commonShareIntro,
            ),
            const _SectionGap(),
            if (widget.numberReport)
              ..._buildNumberFields(l10n)
            else
              ..._buildPostFields(l10n),
            if (_error != null) ...[
              const _SectionGap(),
              _ErrorNote(message: _error!),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNumberFields(AppLocalizations l10n) {
    final tokens = context.tokens;
    return [
      _FieldLabel(l10n.reportTabNumberLabel),
      SizedBox(height: tokens.space.md),
      TextFormField(
        controller: _numberController,
        validator: _validateNumber,
        enabled: !_submitting,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        style: _fieldTextStyle(context, emphasis: true),
        decoration: _fieldDecoration(
          context,
          l10n.reportTabNumberHint,
          prefixIcon: LucideIcons.phone,
        ),
      ),
      const _SectionGap(),
      _FieldLabel(l10n.reportTabReasonLabel),
      SizedBox(height: tokens.space.md),
      for (final _ReasonOption option in _reasonOptions(l10n)) ...[
        _ReasonTile(
          option: option,
          selected: option.value == _reason,
          onTap: _submitting
              ? null
              : () => setState(() => _reason = option.value),
        ),
        SizedBox(height: tokens.space.md),
      ],
    ];
  }

  List<Widget> _buildPostFields(AppLocalizations l10n) {
    final tokens = context.tokens;
    return [
      _FieldLabel(l10n.commonTitle),
      SizedBox(height: tokens.space.md),
      TextFormField(
        controller: _titleController,
        validator: _validateTitle,
        enabled: !_submitting,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        style: _fieldTextStyle(context, emphasis: true),
        decoration: _fieldDecoration(context, l10n.commonTitleHint),
      ),
      const _SectionGap(),
      Row(
        children: [
          Expanded(child: _FieldLabel(l10n.commonMessage)),
          TextButton.icon(
            onPressed: _submitting ? null : _pasteMessage,
            icon: const Icon(LucideIcons.clipboardPaste, size: 24),
            label: Text(
              l10n.reportTabPaste,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.symmetric(horizontal: tokens.space.md),
            ),
          ),
        ],
      ),
      SizedBox(height: tokens.space.sm),
      TextFormField(
        controller: _textController,
        validator: _validateText,
        enabled: !_submitting,
        minLines: 5,
        maxLines: 12,
        textCapitalization: TextCapitalization.sentences,
        style: _fieldTextStyle(context),
        decoration: _fieldDecoration(context, l10n.commonMessageHint),
      ),
      const _SectionGap(),
      _FieldLabel(l10n.commonPhotos),
      SizedBox(height: tokens.space.md),
      _PhotoGrid(
        images: _images,
        enabled: !_submitting,
        addLabel: l10n.commonAddPhoto,
        removeLabel: l10n.commonRemovePhoto,
        onAdd: _addPhoto,
        onRemove: _removePhoto,
      ),
    ];
  }
}

TextStyle? _fieldTextStyle(BuildContext context, {bool emphasis = false}) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyLarge?.copyWith(
    fontSize: emphasis ? 20 : 18,
    fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
    height: 1.4,
  );
}

InputDecoration _fieldDecoration(
  BuildContext context,
  String hint, {
  IconData? prefixIcon,
}) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  final OutlineInputBorder base = OutlineInputBorder(
    borderRadius: tokens.radii.mdRadius,
    borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
    errorStyle: TextStyle(fontSize: 16, color: context.tokens.risk.danger),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 24, color: scheme.onSurfaceVariant),
    border: base,
    enabledBorder: base,
    focusedBorder: base.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 2),
    ),
    errorBorder: base.copyWith(
      borderSide: BorderSide(color: tokens.risk.danger, width: 1.5),
    ),
    focusedErrorBorder: base.copyWith(
      borderSide: BorderSide(color: tokens.risk.danger, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: tokens.space.lg,
      vertical: tokens.space.lg + tokens.space.xs,
    ),
  );
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: context.tokens.space.xl2);
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return AppCard(
      color: scheme.primary.withValues(alpha: 0.06),
      border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: scheme.primary),
          ),
          SizedBox(width: tokens.space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.space.sm),
                Text(
                  body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
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
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReasonOption {
  const _ReasonOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
  });

  final String value;
  final IconData icon;
  final String label;
  final String description;
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ReasonOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(tokens.space.lg),
        color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1.5,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.16)
                    : scheme.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon,
                size: 26,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: tokens.space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.space.xs),
                  Text(
                    option.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(LucideIcons.check, size: 20, color: scheme.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.images,
    required this.enabled,
    required this.addLabel,
    required this.removeLabel,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> images;
  final bool enabled;
  final String addLabel;
  final String removeLabel;
  final VoidCallback onAdd;
  final ValueChanged<XFile> onRemove;

  static const double _tileSize = 104;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Wrap(
      spacing: tokens.space.md,
      runSpacing: tokens.space.md,
      children: [
        for (final XFile image in images)
          _PhotoThumbnail(
            file: image,
            size: _tileSize,
            removeLabel: removeLabel,
            onRemove: enabled ? () => onRemove(image) : null,
          ),
        _AddPhotoTile(
          size: _tileSize,
          label: addLabel,
          onTap: enabled ? onAdd : null,
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.size,
    required this.label,
    required this.onTap,
  });

  final double size;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: scheme.primary.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: tokens.radii.mdRadius,
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.imagePlus, size: 32, color: scheme.primary),
              SizedBox(height: tokens.space.sm),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space.xs),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.file,
    required this.size,
    required this.removeLabel,
    required this.onRemove,
  });

  final XFile file;
  final double size;
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: tokens.radii.mdRadius,
            child: Image.file(File(file.path), fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: removeLabel,
              onPressed: onRemove,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(tokens.space.lg),
        decoration: BoxDecoration(
          color: tokens.risk.dangerContainer,
          borderRadius: tokens.radii.mdRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleAlert, size: 26, color: tokens.risk.danger),
            SizedBox(width: tokens.space.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  color: tokens.risk.onDangerContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.submitting,
    required this.label,
    required this.onPressed,
  });

  final bool submitting;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 60,
      child: FilledButton.icon(
        onPressed: submitting ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: tokens.radii.lgRadius),
        ),
        icon: submitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(LucideIcons.send, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.message,
    required this.reportAnotherLabel,
    required this.onReportAnother,
    required this.doneLabel,
    required this.onDone,
  });

  final String message;
  final String reportAnotherLabel;
  final VoidCallback onReportAnother;
  final String doneLabel;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.space.xl3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: tokens.risk.safeContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.risk.safe.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.circleCheck,
                  size: 64,
                  color: tokens.risk.safe,
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.space.xl2),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.reportTabSuccessTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: tokens.space.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.space.xl3),
          if (onDone != null) ...[
            SizedBox(
              height: 60,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: tokens.radii.lgRadius,
                  ),
                ),
                child: Text(
                  doneLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: tokens.space.md),
          ],
          SizedBox(
            height: 60,
            child: OutlinedButton.icon(
              onPressed: onReportAnother,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: tokens.radii.lgRadius,
                ),
                side: BorderSide(color: scheme.primary, width: 1.5),
              ),
              icon: const Icon(LucideIcons.rotateCcw, size: 24),
              label: Text(
                reportAnotherLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
