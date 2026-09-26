import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log_app/background/background_runner.dart';
import 'package:call_log_app/screens/call_history_screen.dart';
import 'package:call_log_app/screens/contacts_screen.dart';
import 'package:call_log_app/screens/notifications_screen.dart';
import 'package:call_log_app/screens/protection_screen.dart';
import 'package:call_log_app/screens/scam_shield_screen.dart';
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
      home: const HomePage(),
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

  final List<Widget> _screens = [
    const CallHistoryScreen(),
    const ContactsScreen(),
    const ProtectionScreen(),
    const NotificationsScreen(),
    const ScamShieldScreen(),
  ];

  final List<_NavigationItem> _items = [
    _NavigationItem(icon: Icons.history, label: 'Call History'),
    _NavigationItem(icon: Icons.contact_mail, label: 'Contacts'),
    _NavigationItem(icon: Icons.security, label: 'Protection'),
    _NavigationItem(icon: Icons.notifications_active, label: 'Notifications'),
    _NavigationItem(icon: Icons.smart_toy, label: 'Scam AI'),
  ];

  @override
  void initState() {
    super.initState();
    _ensureNotificationPermission();
    _syncShieldFlag();
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

  Future<void> _ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _screens[_currentIndex],
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
