import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scamwatch_mobile_app/api/api_client.dart';
import 'package:scamwatch_mobile_app/background/background_runner.dart';
import 'package:scamwatch_mobile_app/screens/calls/call_history_screen.dart';
import 'package:scamwatch_mobile_app/screens/community/my_posts_screen.dart';
import 'package:scamwatch_mobile_app/screens/home/home_screen.dart';
import 'package:scamwatch_mobile_app/screens/community/report_tab_screen.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/onboarding_screen.dart';
import 'package:scamwatch_mobile_app/screens/safety/safety_screen.dart';
import 'package:scamwatch_mobile_app/screens/settings/settings_page.dart';
import 'package:scamwatch_mobile_app/services/protection_settings.dart';
import 'package:scamwatch_mobile_app/services/scamshield_channels.dart';
import 'package:scamwatch_mobile_app/state/auth_controller.dart';
import 'package:scamwatch_mobile_app/state/locale_controller.dart';
import 'package:scamwatch_mobile_app/state/theme_controller.dart';
import 'package:scamwatch_mobile_app/widgets/auth/auth_gate.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/theme/theme.dart';
import 'package:scamwatch_mobile_app/widgets/tour/coach_mark_overlay.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_controller.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final authController = AuthController(client: apiClient);
  authController.bootstrap();
  final tourTargets = CoachMarkTargets(kTourSteps.length);
  final tourController = TourController(steps: kTourSteps);
  final localeController = LocaleController();
  localeController.load();
  final themeController = ThemeController();
  themeController.load();
  runApp(
    MyApp(
      apiClient: apiClient,
      authController: authController,
      tourTargets: tourTargets,
      tourController: tourController,
      localeController: localeController,
      themeController: themeController,
    ),
  );
}

@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundRunner().start();
}

ThemeData _materialTheme(FColors colors) {
  final isDark = colors.brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    extensions: [isDark ? AppTokens.dark : AppTokens.light],
    colorScheme: ColorScheme(
      brightness: colors.brightness,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      secondary: colors.secondary,
      onSecondary: colors.secondaryForeground,
      error: colors.error,
      onError: colors.errorForeground,
      surface: colors.background,
      onSurface: colors.foreground,
    ),
    scaffoldBackgroundColor: colors.background,
    visualDensity: VisualDensity.standard,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        color: colors.foreground,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: colors.foreground,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(color: colors.foreground, letterSpacing: 0),
      bodyMedium: TextStyle(
        color: colors.foreground,
        letterSpacing: 0,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        color: colors.mutedForeground,
        letterSpacing: 0,
        height: 1.3,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.card,
      foregroundColor: colors.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardColor: colors.card,
    dividerColor: colors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: colors.mutedForeground),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.apiClient,
    required this.authController,
    required this.tourTargets,
    required this.tourController,
    required this.localeController,
    required this.themeController,
  });

  final ApiClient apiClient;
  final AuthController authController;
  final CoachMarkTargets tourTargets;
  final TourController tourController;
  final LocaleController localeController;
  final ThemeController themeController;

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
      ],
      child: Consumer2<LocaleController, ThemeController>(
        builder: (context, localeController, themeController, _) => MaterialApp(
          title: 'Call Manager',
          locale: localeController.locale,
          supportedLocales: const [
            ...kAppSupportedLocales,
            ...FLocalizations.supportedLocales,
          ],
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...FLocalizations.localizationsDelegates,
          ],
          theme: _materialTheme(lightColors),
          darkTheme: _materialTheme(darkColors),
          themeMode: themeController.mode,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final clamped = media.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.8,
            );
            return MediaQuery(
              data: media.copyWith(textScaler: clamped),
              child: FTheme(
                data: Theme.brightnessOf(context) == Brightness.light
                    ? lightTheme
                    : darkTheme,
                child: FToaster(
                  child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
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
    _NavigationItem(icon: LucideIcons.house, label: (l10n) => l10n.homeTitle),
    _NavigationItem(icon: LucideIcons.phone, label: (l10n) => l10n.callHistoryTitle),
    _NavigationItem(icon: LucideIcons.shield, label: (l10n) => l10n.safetyTitle),
    _NavigationItem(icon: LucideIcons.megaphone, label: (l10n) => l10n.reportTabTitle),
    _NavigationItem(icon: LucideIcons.fileText, label: (l10n) => l10n.myPostsTitle),
    _NavigationItem(
      icon: LucideIcons.settings,
      label: (l10n) => l10n.settingsScreenTitle,
    ),
  ];

  TourController? _tour;

  @override
  void initState() {
    super.initState();
    _syncShieldFlag();
    _deeplink.setMethodCallHandler(_onDeeplink);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
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
    super.dispose();
  }

  void _showTab(int tabIndex) {
    if (!mounted) return;
    if (tabIndex < 0 || tabIndex >= _items.length) return;
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
    final args = call.arguments as Map?;
    if (args == null) return;
    final subject = args['subject'] as String? ?? '';
    final content = args['content'] as String? ?? '';
    final source = args['source'] as String? ?? 'call';
    if (!mounted) return;
    final client = context.read<ApiClient>();
    if (source == 'call') {
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => ReportTabScreen(
          client: client,
          prefillTitle: subject,
          prefillText: content.isEmpty ? subject : content,
        ),
      ),
    );
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
      const AuthGate(child: SafetyScreen()),
      AuthGate(child: ReportTabScreen(client: client)),
      AuthGate(child: MyPostsScreen(client: client)),
      const SettingsPage(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CoachMarkOverlay(
          controller: tour,
          targets: targets,
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _AppNavBar(
        items: _items,
        currentIndex: _currentIndex,
        targets: targets,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// Custom bottom navigation bar. Replaces Material's [NavigationBar], which
/// clipped long labels like "Call History" (every destination gets equal width
/// with no graceful shrink). Each tab shrinks its label to fit via [FittedBox],
/// and the active tab shows a soft rounded pill behind the icon built from the
/// app design tokens. Preserves the coach-mark [CoachMarkTargets] keys so the
/// feature tour still points at the right tabs.
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
        child: SizedBox(
          height: 68,
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
                    inactive: colors.mutedForeground,
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: space.xs,
          vertical: space.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: space.lg,
                vertical: space.xs,
              ),
              decoration: BoxDecoration(
                color: selected ? pill : Colors.transparent,
                borderRadius: radii.pillRadius,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            SizedBox(height: space.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
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

