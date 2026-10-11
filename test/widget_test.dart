import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:call_log_app/api/api_client.dart';
import 'package:call_log_app/main.dart';
import 'package:call_log_app/screens/blocked_numbers_screen.dart';
import 'package:call_log_app/state/auth_controller.dart';
import 'package:call_log_app/theme/theme.dart';

MyApp _buildApp() {
  final client = ApiClient();
  final auth = AuthController(client: client);
  return MyApp(apiClient: client, authController: auth);
}

Future<void> _pumpFrames(
  WidgetTester tester, {
  int frames = 15,
  bool Function()? done,
}) async {
  for (var i = 0; i < frames; i++) {
    if (done != null && done()) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpSignedIn(WidgetTester tester) async {
  await tester.pumpWidget(_buildApp());
  await tester.pump(const Duration(seconds: 1));

  await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
  await tester.pump(const Duration(seconds: 1));
  await _pumpFrames(
    tester,
    done: () => find.text('Call History').evaluate().isNotEmpty,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Get Started enters the app without credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pump(const Duration(seconds: 1));
    await _pumpFrames(
      tester,
      done: () => find.text('Call History').evaluate().isNotEmpty,
    );

    expect(find.text('Call History'), findsWidgets);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Call History tab loads', (WidgetTester tester) async {
    await _pumpSignedIn(tester);

    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Bottom bar shows the five simplified tabs', (
    WidgetTester tester,
  ) async {
    await _pumpSignedIn(tester);

    expect(find.text('Calls'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Tab switching works', (WidgetTester tester) async {
    await _pumpSignedIn(tester);

    await tester.tap(find.text('Safety'));
    await tester.pump(const Duration(seconds: 1));
    await _pumpFrames(
      tester,
      done: () => find.textContaining('Protection').evaluate().isNotEmpty,
    );

    expect(find.textContaining('Protection'), findsWidgets);
  });

  testWidgets('Blocked numbers render as Forui tiles', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'spam_blocked_numbers': '5551234,5559876',
    });

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => FTheme(
          data: lightTheme,
          child: FToaster(child: child ?? const SizedBox.shrink()),
        ),
        home: const BlockedNumbersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5551234'), findsOneWidget);
    expect(find.text('5559876'), findsOneWidget);
  });
}
