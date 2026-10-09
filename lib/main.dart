import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:call_log_app/background/background_runner.dart';
import 'package:call_log_app/screens/call_history_screen.dart';
import 'package:call_log_app/screens/login_screen.dart';
import 'package:call_log_app/screens/notifications_screen.dart';
import 'package:call_log_app/screens/report_screen.dart';
import 'package:call_log_app/screens/scam_shield_screen.dart';
import 'package:call_log_app/screens/settings_screen.dart';
import 'package:call_log_app/services/protection_settings.dart';
import 'package:call_log_app/services/scamshield_channels.dart';
import 'package:call_log_app/theme/theme.dart';

void main() {
  runApp(const MyApp());
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Manager',
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      theme: _materialTheme(lightColors),
      darkTheme: _materialTheme(darkColors),
      builder: (context, child) => FTheme(
        data: Theme.brightnessOf(context) == Brightness.light
            ? lightTheme
            : darkTheme,
        child: FToaster(
          child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
        ),
      ),
      home: const LoginScreen(),
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
  final GlobalKey<ReportScreenState> _reportKey =
      GlobalKey<ReportScreenState>();
  ReportDeepLinkPayload? _pendingReport;

  final List<_NavigationItem> _items = [
    _NavigationItem(icon: Icons.history, label: 'Call History'),
    _NavigationItem(icon: Icons.smart_toy, label: 'Scam AI'),
    _NavigationItem(icon: Icons.flag, label: 'Report'),
    _NavigationItem(icon: Icons.notifications_active, label: 'Notifications'),
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
    setState(
      () => _currentIndex = _items.indexWhere((item) => item.label == 'Report'),
    );
    final state = _reportKey.currentState;
    if (state != null) {
      state.prefillFromLink(payload);
    } else {
      _pendingReport = payload;
    }
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
    final pending = _pendingReport;
    _pendingReport = null;
    final screens = [
      const CallHistoryScreen(),
      const ScamShieldScreen(),
      ReportScreen(key: _reportKey, initialLink: pending),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: context.theme.colors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: context.theme.colors.primaryForeground,
                    child: Icon(
                      Icons.phone,
                      size: 36,
                      color: context.theme.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Call Manager',
                    style: TextStyle(
                      color: context.theme.colors.primaryForeground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_items.length, (index) {
              return ListTile(
                leading: Icon(_items[index].icon),
                title: Text(_items[index].label),
                selected: _currentIndex == index,
                selectedTileColor: context.theme.colors.muted,
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Call Manager',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.phone),
                );
              },
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
                selectedIcon:
                    Icon(item.icon, color: context.theme.colors.primary),
              ),
            )
            .toList(),
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

