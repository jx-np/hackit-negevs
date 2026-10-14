import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:call_log_app/api/api_client.dart';
import 'package:call_log_app/background/background_runner.dart';
import 'package:call_log_app/screens/calls/call_history_screen.dart';
import 'package:call_log_app/screens/community/my_posts_screen.dart';
import 'package:call_log_app/screens/community/report_tab_screen.dart';
import 'package:call_log_app/screens/auth/login_register_screen.dart';
import 'package:call_log_app/screens/auth/login_screen.dart';
import 'package:call_log_app/screens/safety/safety_screen.dart';
import 'package:call_log_app/screens/settings/settings_page.dart';
import 'package:call_log_app/services/protection_settings.dart';
import 'package:call_log_app/services/scamshield_channels.dart';
import 'package:call_log_app/state/auth_controller.dart';
import 'package:call_log_app/state/locale_controller.dart';
import 'package:call_log_app/theme/theme.dart';
import 'package:call_log_app/widgets/tour/coach_mark_overlay.dart';
import 'package:call_log_app/widgets/tour/tour_controller.dart';
import 'package:call_log_app/widgets/tour/tour_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final authController = AuthController(client: apiClient);
  authController.bootstrap();
  final tourTargets = CoachMarkTargets(kTourSteps.length);
  final tourController = TourController(steps: kTourSteps);
  final localeController = LocaleController();
  localeController.load();
  runApp(
    MyApp(
      apiClient: apiClient,
      authController: authController,
      tourTargets: tourTargets,
      tourController: tourController,
      localeController: localeController,
    ),
  );
}

@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundRunner().start();
}

ThemeData _materialTheme(FColors colors) {
  return ThemeData(
    useMaterial3: true,
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
  });

  final ApiClient apiClient;
  final AuthController authController;
  final CoachMarkTargets tourTargets;
  final TourController tourController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<CoachMarkTargets>.value(value: tourTargets),
        ChangeNotifierProvider<TourController>.value(value: tourController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
      ],
      child: Consumer<LocaleController>(
        builder: (context, localeController, _) => MaterialApp(
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
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.signedOut:
        return const LoginRegisterScreen();
      case AuthStatus.signedIn:
        return const LoginScreen();
    }
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
    _NavigationItem(icon: Icons.phone, label: (l10n) => l10n.callHistoryTitle),
    _NavigationItem(icon: Icons.shield, label: (l10n) => l10n.safetyTitle),
    _NavigationItem(icon: Icons.campaign, label: (l10n) => l10n.reportTabTitle),
    _NavigationItem(icon: Icons.article, label: (l10n) => l10n.myPostsTitle),
    _NavigationItem(
      icon: Icons.settings,
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
    final l10n = AppLocalizations.of(context);
    final client = context.read<ApiClient>();
    final tour = context.read<TourController>();
    final targets = context.read<CoachMarkTargets>();
    final screens = [
      const CallHistoryScreen(),
      const SafetyScreen(),
      ReportTabScreen(client: client),
      MyPostsScreen(client: client),
      const SettingsPage(),
    ];
    return Scaffold(
      body: CoachMarkOverlay(
        controller: tour,
        targets: targets,
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 84,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: context.theme.colors.card,
            indicatorColor: context.theme.colors.primary.withValues(
              alpha: 0.15,
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? context.theme.colors.primary
                    : context.theme.colors.mutedForeground,
              );
            }),
          ),
        child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              for (var i = 0; i < _items.length; i++)
                NavigationDestination(
                  icon: KeyedSubtree(
                    key: targets.keyForTab(i),
                    child: Icon(_items[i].icon, size: 30),
                  ),
                  label: _items[i].label(l10n),
                  selectedIcon: Icon(
                    _items[i].icon,
                    size: 30,
                    color: context.theme.colors.primary,
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

