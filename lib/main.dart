import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:call_log_app/api/api_client.dart';
import 'package:call_log_app/background/background_runner.dart';
import 'package:call_log_app/screens/call_history_screen.dart';
import 'package:call_log_app/screens/community/my_posts_screen.dart';
import 'package:call_log_app/screens/community/report_tab_screen.dart';
import 'package:call_log_app/screens/login_screen.dart';
import 'package:call_log_app/screens/report_screen.dart';
import 'package:call_log_app/screens/safety_screen.dart';
import 'package:call_log_app/screens/settings_screen.dart';
import 'package:call_log_app/services/protection_settings.dart';
import 'package:call_log_app/services/scamshield_channels.dart';
import 'package:call_log_app/state/auth_controller.dart';
import 'package:call_log_app/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final authController = AuthController(client: apiClient);
  authController.bootstrap();
  runApp(MyApp(apiClient: apiClient, authController: authController));
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
  });

  final ApiClient apiClient;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthController>.value(value: authController),
      ],
      child: MaterialApp(
        title: 'Call Manager',
        supportedLocales: FLocalizations.supportedLocales,
        localizationsDelegates: const [...FLocalizations.localizationsDelegates],
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
        home: const LoginScreen(),
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _syncShieldFlag();
    _deeplink.setMethodCallHandler(_onDeeplink);
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
    final screens = [
      const CallHistoryScreen(),
      const SafetyScreen(),
      ReportTabScreen(client: client),
      MyPostsScreen(client: client),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: screens[_currentIndex],
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
            destinations: _items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon, size: 30),
                    label: item.label,
                    selectedIcon: Icon(
                      item.icon,
                      size: 30,
                      color: context.theme.colors.primary,
                    ),
                  ),
                )
                .toList(),
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

