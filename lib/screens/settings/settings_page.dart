import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/app_screen.dart';
import '../../core/model_catalog.dart';
import '../../services/model_controller.dart';
import '../../services/protection_settings.dart';
import '../../services/scamshield_channels.dart';
import '../../state/auth_controller.dart';
import '../../state/locale_controller.dart';
import '../../state/theme_controller.dart';
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
          ok ? '${_model.spec.displayName} is ready' : _model.error,
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
    final tokens = context.tokens;
    return AppScreen(
      title: 'Settings',
      scrollable: false,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.space.lg,
            tokens.space.lg,
            tokens.space.lg,
            tokens.space.xl2,
          ),
          children: [
            _protectionSummary(),
            SizedBox(height: tokens.space.xl2),
            _protectionSection(),
            SizedBox(height: tokens.space.xl2),
            _speedSection(),
            SizedBox(height: tokens.space.xl2),
            _appSection(),
            SizedBox(height: tokens.space.xl2),
            _accountSection(),
            if (kDebugMode) ...[
              SizedBox(height: tokens.space.xl2),
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
    return SettingsSection(
      title: 'Scam checker',
      caption:
          'A small assistant runs on your phone and quietly reviews messages '
          'for common scam patterns. Nothing leaves your device.',
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

    final String statusLine;
    if (!_serviceRunning) {
      statusLine = 'Protection is off';
    } else if (downloading) {
      statusLine = 'Getting ready…';
    } else if (ready) {
      statusLine = 'Protection is on';
    } else {
      statusLine = 'Protection needs a model';
    }

    final String detail;
    if (downloading) {
      detail = _downloadLabel(model, progress);
    } else if (ready) {
      detail = '${model.spec.displayName} · ready to protect you';
    } else {
      detail = '${model.spec.displayName} · not downloaded yet';
    }

    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return SettingsSection(
      title: 'Status',
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
    final received = model.receivedBytes;
    final total = model.totalBytes;
    if (total > 0) {
      final gotMb = (received / (1024 * 1024)).round();
      final totalMb = (total / (1024 * 1024)).round();
      return 'Setting up… $progress% · $gotMb of $totalMb MB';
    }
    if (received > 0) {
      final gotMb = (received / (1024 * 1024)).round();
      return 'Setting up… $gotMb MB';
    }
    return 'Setting up… $progress%';
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

    final String subtitle;
    if (downloading) {
      subtitle = _downloadLabel(model, progress);
    } else if (ready) {
      subtitle = 'Ready to protect you';
    } else if (spec.isBuiltIn) {
      subtitle = 'Android system model · no app download';
    } else {
      subtitle = 'About ${spec.approxSizeMb} MB';
    }

    return SettingsRow(
      enabled: !model.busy || selected,
      leading: Icon(
        selected ? LucideIcons.circleDot : LucideIcons.circle,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: spec.displayName,
      subtitle: subtitle,
      trailing: _modelTileAction(spec, selected, downloading, ready, progress),
      onTap: () => _selectModel(spec),
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
        child: const Text('Remove'),
      );
    }
    if (!ready) {
      return TextButton(
        onPressed: model.busy
            ? null
            : () => _downloadFor(spec),
        child: Text(spec.isBuiltIn ? 'Prepare' : 'Download'),
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
    return SettingsSection(
      title: 'AI Compatibility mode',
        caption: 'Automatic picks the fastest compatible hardware. Pin a '
          'specific one only if Automatic has trouble on your phone.',
      children: [
        SettingsRow(
          leading: const Icon(LucideIcons.sparkles),
          title: 'Automatic',
          subtitle: 'Recommended · best compatible hardware',
          trailing: _backend == ModelBackend.npu
              ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.npu),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.cpu),
          title: 'CPU',
          subtitle: 'Most compatible, slowest',
          trailing: _backend == ModelBackend.cpu
              ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.cpu),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.zap),
          title: 'GPU',
          subtitle: 'Faster on phones with a supported graphics chip',
          trailing: _backend == ModelBackend.gpu
              ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.gpu),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.microchip),
          title: 'NPU',
          subtitle: 'Fastest on phones with a dedicated AI chip',
          trailing: _backend == ModelBackend.forceNpu
              ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () => _setBackend(ModelBackend.forceNpu),
        ),
        if (kDebugMode) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          SettingsRow(
            leading: const Icon(LucideIcons.codeXml),
            title: 'NPU test (force)',
            subtitle: 'Debug only: send the current model directly to NPU',
            trailing: _backend == ModelBackend.npuTest
                ? Icon(
                    LucideIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => _setBackend(ModelBackend.npuTest),
          ),
        ],
      ],
    );
  }

  Widget _appSection() {
    final localeController = context.watch<LocaleController>();
    final themeController = context.watch<ThemeController>();
    return SettingsSection(
      title: 'App',
      children: [
        SettingsRow(
          leading: Icon(_themeIcon(themeController.mode)),
          title: 'Appearance',
          subtitle: _themeLabel(themeController.mode),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: _showThemePicker,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.languages),
          title: 'Language',
          subtitle: _languageLabel(localeController.locale?.languageCode),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: _showLanguagePicker,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.graduationCap),
          title: 'Show the tour again',
          subtitle: 'Replay the quick walkthrough',
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => context.read<TourController>().start(),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        SettingsRow(
          leading: const Icon(LucideIcons.shieldCheck),
          title: 'Permissions',
          subtitle: 'Check what the app is allowed to do',
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => AppScreen(
                  title: 'Permissions',
                  scrollable: false,
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
    return SettingsSection(
      title: 'Protection',
      children: [
        SettingsRow(
          enabled: _serviceRunning,
          leading: Icon(
            _serviceRunning
                ? LucideIcons.circleStop
                : LucideIcons.circlePause,
          ),
          title: 'Pause protection',
          subtitle:
            _serviceRunning ? 'Currently running' : 'Currently paused',
          onTap: _serviceRunning ? _stopProtection : null,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        if (signedIn)
          SettingsRow(
            leading: const Icon(LucideIcons.logOut),
            title: 'Sign out',
            subtitle: user?.email ?? 'You can sign back in at any time',
            onTap: () => context.read<AuthController>().logout(),
          )
        else
          SettingsRow(
            leading: const Icon(LucideIcons.logIn),
            title: 'Sign in',
            subtitle: 'Needed for community posts and cloud review',
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => requireLogin(context),
          ),
      ],
    );
  }

  // Debug-only: everything technical lives here so the normal UI stays simple.
  Widget _devSection() {
    return SettingsSection(
      title: 'Dev menu',
      caption: 'Debug build only. Not shown in release builds.',
      children: [
        SettingsRow(
          leading: const Icon(LucideIcons.terminal),
          title: 'Open Dev menu',
          subtitle: 'Custom models, cloud review, backend details',
          trailing: const Icon(LucideIcons.chevronRight),
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

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return LucideIcons.sun;
      case ThemeMode.dark:
        return LucideIcons.moon;
      case ThemeMode.system:
        return LucideIcons.smartphone;
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
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
              for (final entry in const [
                MapEntry(ThemeMode.system, 'System default'),
                MapEntry(ThemeMode.light, 'Light'),
                MapEntry(ThemeMode.dark, 'Dark'),
              ])
                RadioListTile<ThemeMode>(
                  value: entry.key,
                  title: Text(entry.value),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await controller.setMode(selected);
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
        return 'System default';
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
              for (final entry in const [
                MapEntry('__system__', 'System default'),
                MapEntry('en', 'English'),
                MapEntry('zh', '中文'),
                MapEntry('ta', 'தமிழ்'),
                MapEntry('ms', 'Melayu'),
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
