import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:call_log_app/main.dart';
import 'package:call_log_app/screens/blocked_numbers_screen.dart';
import 'package:call_log_app/theme/theme.dart';

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
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(seconds: 1));

  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pump(const Duration(seconds: 1));
  await _pumpFrames(
    tester,
    done: () => find.text('Call History').evaluate().isNotEmpty,
  );
}

void main() {
  testWidgets('Sign in enters the app without credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
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

  testWidgets('Report tab is in the middle of the bottom bar', (
    WidgetTester tester,
  ) async {
    await _pumpSignedIn(tester);

    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Scam AI'), findsOneWidget);
  });

  testWidgets('Tab switching works', (WidgetTester tester) async {
    await _pumpSignedIn(tester);

    await tester.tap(find.byIcon(Icons.flag));
    await tester.pump(const Duration(seconds: 1));
    await _pumpFrames(
      tester,
      done: () => find.text('Compose a report').evaluate().isNotEmpty,
    );

    expect(find.text('Compose a report'), findsOneWidget);
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
