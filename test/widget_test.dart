import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:call_log_app/main.dart';
import 'package:call_log_app/screens/blocked_numbers_screen.dart';
import 'package:call_log_app/theme/theme.dart';

void main() {
  testWidgets('Call History tab loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Navigation drawer opens', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Contacts'), findsWidgets);
  });

  testWidgets('Tab switching works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.contact_mail));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Contacts'), findsWidgets);
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
