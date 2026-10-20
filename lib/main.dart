import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' as material_ui;
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/api/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scamwatch_mobile_app/background/background_runner.dart';
import 'package:scamwatch_mobile_app/screens/calls/call_history_screen.dart';
import 'package:scamwatch_mobile_app/screens/home/home_screen.dart';
import 'package:scamwatch_mobile_app/screens/community/report_tab_screen.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/onboarding_screen.dart';
import 'package:scamwatch_mobile_app/screens/profile/my_profile_screen.dart';
import 'package:scamwatch_mobile_app/screens/safety/safety_screen.dart';
import 'package:scamwatch_mobile_app/services/notification_log.dart';
import 'package:scamwatch_mobile_app/services/protection_settings.dart';
import 'package:scamwatch_mobile_app/services/scamshield_channels.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';
import 'package:scamwatch_mobile_app/state/locale_controller.dart';
import 'package:scamwatch_mobile_app/state/posts_refresh_signal.dart';
import 'package:scamwatch_mobile_app/state/text_size_controller.dart';
import 'package:scamwatch_mobile_app/state/theme_controller.dart';
import 'package:scamwatch_mobile_app/widgets/auth/auth_gate.dart';
import 'package:scamwatch_mobile_app/widgets/auth/require_login.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/theme/material_theme.dart';
import 'package:scamwatch_mobile_app/theme/theme.dart';
import 'package:scamwatch_mobile_app/widgets/tour/coach_mark_overlay.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_controller.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _mirrorApiBaseUrl();
  final apiClient = ApiClient();
  final authController = AuthController(client: apiClient);
  authController.bootstrap();
  final tourTargets = CoachMarkTargets(kTourTabCount);
  final tourController = TourController(steps: kTourSteps);
  final localeController = LocaleController();
  localeController.load();
  final themeController = ThemeController();
  themeController.load();
  final textSizeController = TextSizeController();
  textSizeController.load();
  runApp(
    MyApp(
      apiClient: apiClient,
      authController: authController,
      tourTargets: tourTargets,
      tourController: tourController,
      localeController: localeController,
      themeController: themeController,
      textSizeController: textSizeController,
    ),
  );
}

/// The native high-risk call overlay runs without Flutter and reads the API
/// base URL from the legacy shared-preferences file (`flutter.api_base_url`).
Future<void> _mirrorApiBaseUrl() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', ApiConfig.baseUrl);
  } catch (_) {}
}

@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundRunner().start();
}

// Built in lib/theme/material_theme.dart so tests can use the same theme.
ThemeData _materialTheme(FColors colors) => buildMaterialTheme(colors);

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.apiClient,
    required this.authController,
    required this.tourTargets,
    required this.tourController,
    required this.localeController,
    required this.themeController,
    required this.textSizeController,
  });

  final ApiClient apiClient;
  final AuthController authController;
  final CoachMarkTargets tourTargets;
  final TourController tourController;
  final LocaleController localeController;
  final ThemeController themeController;
  final TextSizeController textSizeController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<CoachMarkTargets>.value(value: tourTargets),
        ChangeNotifierProvider<TourController>.value(value: tourController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<TextSizeController>.value(
          value: textSizeController,
        ),
        ChangeNotifierProvider<PostsRefreshSignal>(
          create: (_) => PostsRefreshSignal(),
        ),
      ],
      child: Consumer3<LocaleController, ThemeController, TextSizeController>(
        builder:
            (
              context,
              localeController,
              themeController,
              textSizeController,
              _,
            ) => MaterialApp(
              title: 'Call Manager',
              locale: localeController.locale,
              supportedLocales: const [
                ...kAppSupportedLocales,
                ...FLocalizations.supportedLocales,
              ],
              localizationsDelegates: [
                ...AppLocalizations.localizationsDelegates,
                ...FLocalizations.localizationsDelegates,
                // pro_image_editor is built on material_ui, which looks up its
                // own MaterialLocalizations rather than Flutter's.
                ...material_ui.GlobalMaterialLocalizations.delegates,
              ],
              theme: _materialTheme(lightColors),
              darkTheme: _materialTheme(darkColors),
              themeMode: themeController.mode,
              builder: (context, child) {
                final media = MediaQuery.of(context);
                // The device font-size setting and the in-app choice stack. Cap the
                // product so "Extra large" on a phone already set to maximum stays
                // usable instead of shredding every layout.
                final systemScale = media.textScaler.scale(16) / 16;
                final combined = (systemScale * textSizeController.size.factor)
                    .clamp(1.0, 2.0);
                return MediaQuery(
                  data: media.copyWith(textScaler: TextScaler.linear(combined)),
                  child: FTheme(
                    data: Theme.brightnessOf(context) == Brightness.light
                        ? lightTheme
                        : darkTheme,
                    child: FToaster(
                      child: FTooltipGroup(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
              home: const _RootGate(),
            ),
      ),
    );
  }
}

/// Decides the first screen on launch. Onboarding comes first; the app is fully
/// usable without an account. Sign-in is only prompted for features that need
/// it (see [requireLogin]). Once onboarding is complete we go straight to the
/// app on every subsequent launch, regardless of auth status.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  final ProtectionSettings _settings = ProtectionSettings();
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await _settings.onboardingComplete();
    if (!mounted) return;
    setState(() => _onboarded = done);
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = _onboarded;
    if (onboarded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return onboarded ? const HomePage() : const OnboardingScreen();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  static const MethodChannel _deeplink = MethodChannel('report/deeplink');

  final List<_NavigationItem> _items = [
    _NavigationItem(icon: LucideIcons.house, label: (l10n) => l10n.navHome),
    _NavigationItem(icon: LucideIcons.phone, label: (l10n) => l10n.navCalls),
    _NavigationItem(icon: LucideIcons.shield, label: (l10n) => l10n.navSafety),
    _NavigationItem(
      icon: LucideIcons.megaphone,
      label: (l10n) => l10n.navReport,
    ),
    _NavigationItem(
      icon: LucideIcons.circleUserRound,
      label: (l10n) => l10n.navProfile,
    ),
  ];

  TourController? _tour;

  @override
  void initState() {
    super.initState();
    _syncShieldFlag();
    _deeplink.setMethodCallHandler(_onDeeplink);
    // A notification's "Report" action can cold-start the app: the native side
    // delivers the deeplink in configureFlutterEngine, before this handler
    // exists, and buffers it. Pull that buffered report now that we're live.
    _consumePendingReport();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  Future<void> _consumePendingReport() async {
    try {
      final pending = await _deeplink.invokeMethod<Map<dynamic, dynamic>>(
        'getPendingReport',
      );
      if (pending != null) {
        await _onDeeplink(MethodCall('openReport', pending));
      }
    } catch (_) {
      // No buffered report or the native side isn't ready; nothing to do.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tour = context.read<TourController>();
    if (!identical(tour, _tour)) {
      _tour?.onShowTab = null;
      _tour = tour;
      tour.onShowTab = _showTab;
    }
  }

  @override
  void dispose() {
    if (_tour?.onShowTab == _showTab) _tour?.onShowTab = null;
    // Stop native from delivering report deeplinks to a dead State object.
    _deeplink.setMethodCallHandler(null);
    super.dispose();
  }

  void _showTab(int tabIndex) {
    if (!mounted) return;
    if (tabIndex < 0 || tabIndex >= _items.length) return;
    if (tabIndex == _currentIndex) return;
    // Switching tabs is an instant index change with a quick cross-fade
    // (see [_FadeIndexedStack]). All screens stay mounted so their state and
    // polling survive, but only the active one lays out, paints, and ticks —
    // no scrolling through the heavy pages in between.
    setState(() => _currentIndex = tabIndex);
  }

  Future<void> _maybeStartTour() async {
    final tour = _tour;
    if (tour == null || tour.active) return;
    if (await tour.shouldAutoStart()) {
      if (!mounted) return;
      tour.start();
    }
  }

  Future<void> _onDeeplink(MethodCall call) async {
    if (call.method != 'openReport') return;
    final args = call.arguments;
    if (args is! Map) return;
    String str(String key) {
      final value = args[key];
      return value is String ? value : '';
    }

    final subject = str('subject');
    final content = str('content');
    final source = str('source').isEmpty ? 'call' : str('source');
    // Identifies the logged notification this alert came from, so a successful
    // report can remove it from the recent-alerts list.
    final notificationId = str('notificationId');
    if (!mounted) return;
    final client = context.read<ApiClient>();
    if (source == 'call') {
      if (!await requireLogin(context)) return;
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (context) => ReportTabScreen(
            client: client,
            numberReport: true,
            prefillNumber: subject,
          ),
        ),
      );
      return;
    }
    if (!await requireLogin(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => ReportTabScreen(
          client: client,
          prefillTitle: subject,
          prefillText: content.isEmpty ? subject : content,
          onReported: notificationId.isEmpty
              ? null
              : () => _clearReportedAlert(notificationId),
        ),
      ),
    );
  }

  /// Drops a reported scam notification and its conversation from the
  /// recent-alerts list and re-syncs the protection screen's alert count.
  Future<void> _clearReportedAlert(String notificationId) async {
    await NotificationLog().removeThread(notificationId);
    await ScamShieldController.dismissScamAlert();
  }

  Future<void> _syncShieldFlag() async {
    if (!Platform.isAndroid) return;
    try {
      final enabled = await ProtectionSettings().protectionEnabled();
      await ScamShieldController.setShieldEnabled(enabled);
      if (enabled) {
        await ScamShieldController.ensureServiceRunning();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final client = context.read<ApiClient>();
    final tour = context.read<TourController>();
    final targets = context.read<CoachMarkTargets>();
    final screens = [
      HomeScreen(onNavigate: _showTab),
      const CallHistoryScreen(),
      const SafetyScreen(),
      AuthGate(child: ReportTabScreen(client: client)),
      MyProfileScreen(client: client, visible: _currentIndex == 4),
    ];
    // The tour overlay wraps the whole Scaffold so its scrim also covers the
    // bottom nav bar (accidental taps can't switch tabs mid-tour).
    return CoachMarkOverlay(
      controller: tour,
      targets: targets,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          // Tabs change only through the bottom nav. Horizontal swipes used to
          // switch tabs too, but a tremor or an accidental drag while scrolling
          // a list sent users to a different screen; taps are the only switch.
          child: _FadeIndexedStack(index: _currentIndex, children: screens),
        ),
        bottomNavigationBar: _AppNavBar(
          items: _items,
          currentIndex: _currentIndex,
          targets: targets,
          onSelected: _showTab,
        ),
      ),
    );
  }
}

/// Shows one of [children] at a time, keeping them all mounted so their state
/// (scroll position, polling timers, in-flight requests) survives tab changes,
/// while only the active child lays out, paints, and runs animations. Switching
/// index plays a short cross-fade so the swap feels smooth without scrolling
/// through the heavy pages in between (the old [PageView] built and laid out
/// every intermediate screen mid-animation, which dropped frames).
class _FadeIndexedStack extends StatefulWidget {
  const _FadeIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    value: 1,
  );

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _fade
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Freeze off-screen screens' animation controllers so only the visible tab
    // ticks; IndexedStack's Offstage already stops their paint and hit-testing.
    final children = [
      for (var i = 0; i < widget.children.length; i++)
        TickerMode(enabled: i == widget.index, child: widget.children[i]),
    ];
    return FadeTransition(
      opacity: _fade,
      child: IndexedStack(
        index: widget.index,
        sizing: StackFit.expand,
        children: children,
      ),
    );
  }
}

/// Custom bottom navigation bar. Replaces Material's [NavigationBar], which
/// clipped long labels like "Call History" (every destination gets equal width
/// with no graceful shrink). Each tab lets its label wrap to two lines instead
/// of shrinking it, and the active tab shows a soft rounded pill behind the
/// icon built from the app design tokens. Preserves the coach-mark
/// [CoachMarkTargets] keys so the feature tour still points at the right tabs.
class _AppNavBar extends StatelessWidget {
  const _AppNavBar({
    required this.items,
    required this.currentIndex,
    required this.targets,
    required this.onSelected,
  });

  final List<_NavigationItem> items;
  final int currentIndex;
  final CoachMarkTargets targets;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        // Minimum height instead of a fixed one, so the bar grows with large
        // text sizes rather than clipping the labels.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavTab(
                    key: targets.keyForTab(i),
                    icon: items[i].icon,
                    label: items[i].label(l10n),
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                    primary: colors.primary,
                    inactive: secondaryTextColor(colors),
                    pill: colors.primary.withValues(alpha: 0.14),
                    radii: tokens.radii,
                    space: tokens.space,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.inactive,
    required this.pill,
    required this.radii,
    required this.space,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final Color inactive;
  final Color pill;
  final AppRadii radii;
  final AppSpacing space;

  @override
  Widget build(BuildContext context) {
    final color = selected ? primary : inactive;
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space.xs,
            vertical: space.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: space.md,
                  vertical: space.xs,
                ),
                decoration: BoxDecoration(
                  color: selected ? pill : Colors.transparent,
                  borderRadius: radii.pillRadius,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              SizedBox(height: space.xs),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  _NavigationItem({required this.icon, required this.label});

  final IconData icon;
  final String Function(AppLocalizations) label;
}

class ReportDeepLinkPayload {
  const ReportDeepLinkPayload({
    required this.subject,
    required this.content,
    required this.source,
    this.app = '',
    this.notificationKey = '',
  });

  final String subject;
  final String content;
  final String source;
  final String app;
  final String notificationKey;
}
