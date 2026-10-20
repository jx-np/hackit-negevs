import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';

import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../state/text_size_controller.dart';
import '../../state/theme_controller.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/auth/require_login.dart';
import '../../widgets/tour/tour_controller.dart';
import '../permissions/permissions_page.dart';
import 'dev_menu_page.dart';
import 'widgets/settings_section.dart';

/// User-facing settings for the scam-protection app.
///
/// The audience is people who may have just been scammed and are looking for a
/// simple protection tool, so the copy stays plain and calm: no red warnings,
/// no jargon, no alarmist language. Anything technical (custom model files,
/// cloud review, raw endpoints) lives behind the debug-only Dev menu.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ProtectionSettings _settings = ProtectionSettings();
  late final ModelController _model = ModelController(_settings);

  ModelBackend _backend = kDefaultModelBackend;
  bool _serviceRunning = false;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
    _model.load();
    _refresh();
  }

  void _onModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final backend = await _settings.modelBackend();
    final running = await ScamShieldController.isServiceRunning();
    if (!mounted) return;
    setState(() {
      _backend = backend;
      _serviceRunning = running;
    });
  }

  Future<void> _downloadModel() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _model.download();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppLocalizations.of(context).settingsModelReady(
                  _model.spec.displayName,
                )
              : _model.error,
        ),
      ),
    );
    if (ok) await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _deleteModel() async {
    await _model.delete();
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _selectModel(ScamModelSpec spec) async {
    await _model.select(spec);
    await ScamShieldController.syncSettings();
    await _refresh();
  }

  Future<void> _setBackend(ModelBackend backend) async {
    setState(() => _backend = backend);
    await _settings.setModelBackend(backend);
    await ScamShieldController.syncSettings();
  }

  Future<void> _stopProtection() async {
    await _settings.setProtectionEnabled(false);
    await ScamShieldController.setShieldEnabled(false);
    await ScamShieldController.stopService();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsScreenTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _protectionSummary(),
            SizedBox(height: context.tokens.space.xl2),
            _protectionSection(),
            const SizedBox(height: 24),
            _speedSection(),
            const SizedBox(height: 24),
            _appSection(),
            const SizedBox(height: 24),
            _accountSection(),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              _devSection(),
            ],
          ],
        ),
      ),
    );
  }

  // The on-device checker: a plain-language list of the available models, each
  // with its own Download / Remove control. The active model's readiness lives
  // on its own tile; the overall status lives in the summary card up top.
  Widget _protectionSection() {
    final model = _model;
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsCheckerTitle,
      caption: l10n.settingsCheckerCaption,
      children: [
        for (var i = 0; i < allModels.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
          _modelChoiceTile(allModels[i]),
        ],
        if (model.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              model.error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  // A calm one-glance summary: is protection running, and is the chosen model
  // ready. It sits at the very top of the page so the state is obvious before
  // the user scrolls into the detailed controls.
  Widget _protectionSummary() {
    final model = _model;
    final progress = model.progress;
    final downloading = model.busy && progress >= 0 && progress < 100;
    final ready = model.installed || model.spec.isBuiltIn;
    final active = _serviceRunning && ready;
    final l10n = AppLocalizations.of(context);

    final String statusLine;
    if (!_serviceRunning) {
      statusLine = l10n.settingsProtectionOff;
    } else if (downloading) {
      statusLine = l10n.settingsGettingReady;
    } else if (ready) {
      statusLine = l10n.settingsProtectionOn;
    } else {
      statusLine = l10n.settingsProtectionNeedsModel;
    }

    final String detail;
    if (downloading) {
      detail = _downloadLabel(model, progress);
    } else if (ready) {
      detail = l10n.settingsModelReady(model.spec.displayName);
    } else {
      detail = l10n.settingsModelNotDownloaded(model.spec.displayName);
    }

    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSection(
      title: l10n.settingsStatusTitle,
      children: [
        SettingsRow(
          leading: Icon(
            active
                ? LucideIcons.shieldCheck
                : downloading
                    ? LucideIcons.download
                    : LucideIcons.shieldAlert,
            color: color,
          ),
          title: statusLine,
          subtitle: detail,
        ),
        if (downloading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: LinearProgressIndicator(value: progress / 100),
          ),
      ],
    );
  }

  // "Setting up… 23% · 712 of 3100 MB" when the server reports a total,
  // otherwise falls back to just the percent (and bytes if we have them).
  String _downloadLabel(ModelController model, int progress) {
    final l10n = AppLocalizations.of(context);
    final received = model.receivedBytes;
    final total = model.totalBytes;
    if (total > 0) {
      final gotMb = (received / (1024 * 1024)).round();
      final totalMb = (total / (1024 * 1024)).round();
      return l10n.settingsSettingUpProgress(progress, gotMb, totalMb);
    }
    if (received > 0) {
      final gotMb = (received / (1024 * 1024)).round();
      return l10n.settingsSettingUpMb(gotMb);
    }
    return l10n.settingsSettingUpPct(progress);
  }

  Widget _modelChoiceTile(ScamModelSpec spec) {
    final model = _model;
    final selected = spec.id == model.spec.id;
    final progress = model.progress;
    final downloading =
        selected && model.busy && progress >= 0 && progress < 100;
    // Readiness and the Download/Remove control only apply to the active model,
    // because the controller tracks install state for the selected spec. Tap a
    // different tile to make it active first.
    final ready = selected && (model.installed || spec.isBuiltIn);

    // The built-in system model (AICore) only runs on supported devices, and
    // support is a runtime property, so the tile stays greyed out while the
    // probe is still running and whenever the device can't run it. A plain
    // downloadable model is always usable, so it is never gated this way.
    final checkingBuiltIn = spec.isBuiltIn && !model.builtInProbed;
    final unavailable = spec.isBuiltIn && model.builtInProbed && !model.builtInAvailable;

    final l10n = AppLocalizations.of(context);
    final String subtitle;
    if (checkingBuiltIn) {
      subtitle = l10n.settingsCheckingSupport;
    } else if (unavailable) {
      subtitle = l10n.settingsNotAvailable;
    } else if (downloading) {
      subtitle = _downloadLabel(model, progress);
    } else if (ready) {
      subtitle = l10n.settingsReadyShort;
    } else if (spec.isBuiltIn) {
      subtitle = l10n.settingsBuiltInSubtitle;
    } else {
      subtitle = l10n.settingsAboutMb(spec.approxSizeMb);
    }

    // Grey the tile out (ListTile.enabled) while a download is running on
    // another tile, and whenever the built-in option can't be used here.
    final enabled =
        (!model.busy || selected) && !checkingBuiltIn && !unavailable;

    return SettingsRow(
      enabled: enabled,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: spec.displayName,
      subtitle: subtitle,
      trailing: enabled
          ? _modelTileAction(spec, selected, downloading, ready, progress)
          : null,
      onTap: enabled ? () => _selectModel(spec) : null,
    );
  }

  // The inline control on a model tile. The active, installed model shows
  // "Remove"; an active download shows its percent; everything else shows
  // "Download" (or "Prepare" for the built-in system model).
  Widget? _modelTileAction(
    ScamModelSpec spec,
    bool selected,
    bool downloading,
    bool ready,
    int progress,
  ) {
    final model = _model;
    if (downloading) {
      return Text(
        '$progress%',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      );
    }
    if (ready && !spec.isBuiltIn) {
      return TextButton(
        onPressed: model.busy ? null : _deleteModel,
        child: Text(AppLocalizations.of(context).settingsRemove),
      );
    }
    if (!ready) {
      return TextButton(
        onPressed: model.busy
            ? null
            : () => _downloadFor(spec),
        child: Text(
          spec.isBuiltIn
              ? AppLocalizations.of(context).settingsPrepare
              : AppLocalizations.of(context).settingsDownload,
        ),
      );
    }
    return null;
  }

  // Selects the tapped model if needed, then downloads it. Selecting first
  // keeps the controller's install state pointed at the right spec.
  Future<void> _downloadFor(ScamModelSpec spec) async {
    if (spec.id != _model.spec.id) {
      await _selectModel(spec);
      if (!mounted) return;
    }
    await _downloadModel();
  }

  // Pick which hardware the on-device model runs on. Automatic lets the
  // runtime choose the fastest compatible accelerator; the rest pin a target.
  Widget _speedSection() {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsSpeedTitle,
      caption: l10n.settingsSpeedCaption,
      children: [
        _backendRow(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: l10n.settingsSpeedAuto,
          subtitle: l10n.settingsSpeedAutoBody,
          backend: ModelBackend.npu,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _backendRow(
          leading: const Icon(Icons.memory_outlined),
          title: l10n.settingsSpeedCpu,
          subtitle: l10n.settingsSpeedCpuBody,
          backend: ModelBackend.cpu,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _backendRow(
          leading: const Icon(Icons.bolt_outlined),
          title: l10n.settingsSpeedGpu,
          subtitle: l10n.settingsSpeedGpuBody,
          backend: ModelBackend.gpu,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _backendRow(
          leading: const _DoubleBoltIcon(),
          title: l10n.settingsSpeedNpu,
          subtitle: l10n.settingsSpeedNpuBody,
          backend: ModelBackend.forceNpu,
        ),
        if (kDebugMode) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          _backendRow(
            leading: const Icon(Icons.developer_mode_outlined),
            title: 'NPU test (force)',
            subtitle: 'Debug only: send the current model directly to NPU',
            backend: ModelBackend.npuTest,
          ),
        ],
      ],
    );
  }

  Widget _backendRow({
    required Widget leading,
    required String title,
    required String subtitle,
    required ModelBackend backend,
  }) {
    return SettingsRow(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: _backend == backend
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => _setBackend(backend),
    );
  }

  Widget _appSection() {
    final localeController = context.watch<LocaleController>();
    final themeController = context.watch<ThemeController>();
    final textSizeController = context.watch<TextSizeController>();
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsAppSection,
      children: [
        SettingsRow(
          leading: Icon(_themeIcon(themeController.mode)),
          title: l10n.settingsAppearance,
          subtitle: _themeLabel(themeController.mode),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: _showThemePicker,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(Icons.format_size),
          title: l10n.settingsTextSize,
          subtitle: _textSizeLabel(textSizeController.size),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: _showTextSizePicker,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.languages),
          title: l10n.settingsLanguage,
          subtitle: _languageLabel(localeController.locale?.languageCode),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguagePicker,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(Icons.school_outlined),
          title: l10n.settingsShowTutorial,
          subtitle: l10n.settingsReplayTour,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _settings.setSeenPostTour(false);
            context.read<TourController>().start();
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(Icons.shield_outlined),
          title: l10n.settingsScreenPermissionsTab,
          subtitle: l10n.settingsPermissionsSubtitle,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(l10n.settingsScreenPermissionsTab)),
                body: const PermissionsTab(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountSection() {
    final auth = context.watch<AuthController>();
    final signedIn = auth.isSignedIn;
    final user = auth.user;
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsProtection,
      children: [
        SettingsRow(
          enabled: _serviceRunning,
          leading: Icon(
            _serviceRunning
                ? Icons.stop_circle_outlined
                : Icons.pause_circle_outlined,
          ),
          title: l10n.settingsStopProtection,
          subtitle: _serviceRunning
              ? l10n.settingsServiceRunning
              : l10n.settingsServiceStopped,
          onTap: _serviceRunning ? _stopProtection : null,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        if (signedIn)
          SettingsRow(
            leading: const Icon(LucideIcons.logOut),
            title: l10n.settingsSignOut,
            subtitle: user?.email ?? l10n.settingsSignOutSubtitle,
            onTap: () => context.read<AuthController>().logout(),
          )
        else
          SettingsRow(
            leading: const Icon(LucideIcons.logIn),
            title: l10n.settingsSignIn,
            subtitle: l10n.settingsSignInSubtitle,
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => requireLogin(context),
          ),
      ],
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  String _themeLabel(ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsLanguageSystem;
    }
  }

  String _textSizeLabel(AppTextSize size) {
    final l10n = AppLocalizations.of(context);
    switch (size) {
      case AppTextSize.normal:
        return l10n.settingsTextNormal;
      case AppTextSize.large:
        return l10n.settingsTextLarge;
      case AppTextSize.extraLarge:
        return l10n.settingsTextExtraLarge;
    }
  }

  Future<void> _showTextSizePicker() async {
    final controller = context.read<TextSizeController>();
    final selected = await showModalBottomSheet<AppTextSize>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<AppTextSize>(
          groupValue: controller.size,
          onChanged: (value) {
            if (value != null) Navigator.of(sheetContext).pop(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final size in AppTextSize.values)
                RadioListTile<AppTextSize>(
                  value: size,
                  title: Text(_textSizeLabel(size)),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await controller.setSize(selected);
  }

  Future<void> _showThemePicker() async {
    final controller = context.read<ThemeController>();
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: controller.mode,
          onChanged: (value) {
            if (value != null) Navigator.of(sheetContext).pop(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  value: mode,
                  title: Text(_themeLabel(mode)),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await controller.setMode(selected);
  }

  // Debug-only: everything technical lives here so the normal UI stays simple.
  Widget _devSection() {
    return SettingsSection(
      title: 'Dev menu',
      caption: 'Debug build only. Not shown in release builds.',
      children: [
        SettingsRow(
          leading: const Icon(Icons.terminal_outlined),
          title: 'Open Dev menu',
          subtitle: 'Custom models, cloud review, backend details',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DevMenuPage(
                model: _model,
                settings: _settings,
                onChanged: () async {
                  await ScamShieldController.syncSettings();
                  await _refresh();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _languageLabel(String? code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'ta':
        return 'தமிழ்';
      case 'ms':
        return 'Melayu';
      case 'en':
        return 'English';
      default:
        return AppLocalizations.of(context).settingsLanguageSystem;
    }
  }

  Future<void> _showLanguagePicker() async {
    final controller = context.read<LocaleController>();
    final current = controller.locale?.languageCode;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current ?? '__system__',
          onChanged: (value) {
            if (value != null) Navigator.of(sheetContext).pop(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in [
                MapEntry(
                  '__system__',
                  AppLocalizations.of(sheetContext).settingsLanguageSystem,
                ),
                const MapEntry('en', 'English'),
                const MapEntry('zh', '中文'),
                const MapEntry('ta', 'தமிழ்'),
                const MapEntry('ms', 'Melayu'),
              ])
                RadioListTile<String>(
                  value: entry.key,
                  title: Text(entry.value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    if (selected == '__system__') {
      await controller.clearLocale();
    } else {
      await controller.setLocale(Locale(selected));
    }
  }
}

/// Two bolts side by side, shown as the NPU backend icon.
class _DoubleBoltIcon extends StatelessWidget {
  const _DoubleBoltIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 26,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: 1, child: Icon(Icons.bolt, size: 20)),
          Positioned(left: 11, top: 1, child: Icon(Icons.bolt, size: 20)),
        ],
      ),
    );
  }
}
