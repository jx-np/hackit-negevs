import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:call_log_app/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:call_log_app/api/api_client.dart';
import 'package:call_log_app/background/background_runner.dart';
import 'package:call_log_app/screens/call_history_screen.dart';
import 'package:call_log_app/screens/community/my_posts_screen.dart';
import 'package:call_log_app/screens/community/report_tab_screen.dart';
import 'package:call_log_app/screens/auth/login_register_screen.dart';
import 'package:call_log_app/screens/login_screen.dart';
import 'package:call_log_app/screens/report_screen.dart';
import 'package:call_log_app/screens/safety_screen.dart';
import 'package:call_log_app/screens/settings_screen.dart';
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
    appBarTheme: AppBarTheme(
      backgroundColor: colors.card,
      foregroundColor: colors.foreground,
    ),
    cardColor: colors.card,
    dividerColor: colors.border,
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
            minScaleFactor: 1.3,
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
    _NavigationItem(icon: Icons.phone, label: 'Calls'),
    _NavigationItem(icon: Icons.shield, label: 'Safety'),
    _NavigationItem(icon: Icons.campaign, label: 'Report'),
    _NavigationItem(icon: Icons.article, label: 'My Posts'),
    _NavigationItem(icon: Icons.settings, label: 'Settings'),
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
    final payload = ReportDeepLinkPayload(
      subject: args['subject'] as String? ?? '',
      content: args['content'] as String? ?? '',
      source: args['source'] as String? ?? 'call',
      app: args['app'] as String? ?? '',
      notificationKey: args['notificationKey'] as String? ?? '',
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReportScreen(initialLink: payload),
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
      const CallHistoryScreen(),
      const SafetyScreen(),
      ReportTabScreen(client: client),
      MyPostsScreen(client: client),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: CoachMarkOverlay(
        controller: tour,
        targets: targets,
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: MediaQuery.withNoTextScaling(
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 76,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: context.theme.colors.card,
            indicatorColor: context.theme.colors.primary.withValues(
              alpha: 0.15,
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 15,
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
                  label: _items[i].label,
                  selectedIcon: Icon(
                    _items[i].icon,
                    size: 30,
                    color: context.theme.colors.primary,
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
  final IconData icon;
  final String label;

  _NavigationItem({required this.icon, required this.label});
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

