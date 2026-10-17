import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/screens/calls/widgets/call_record_tile.dart';
import 'package:scamwatch_mobile_app/screens/calls/widgets/calls_help.dart';
import 'package:scamwatch_mobile_app/services/protection_settings.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/help/screen_help.dart';
import 'package:scamwatch_mobile_app/widgets/tour/coach_mark_overlay.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_controller.dart';
import 'package:scamwatch_mobile_app/widgets/tour/tour_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phoneSize = Size(360, 690);

/// In-memory stand-in so the tour never touches platform storage.
class _FakeSettings implements ProtectionSettings {
  bool seen = false;

  @override
  Future<bool> seenTutorial() async => seen;

  @override
  Future<void> setSeenTutorial(bool value) async => seen = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Wraps [home] in a MaterialApp with the real tokens and localizations, at
/// the app's maximum text scale (1.8).
Widget _app(Widget home, {List<SingleChildWidget>? providers}) {
  Widget app = MaterialApp(
    theme: ThemeData(useMaterial3: true, extensions: const [AppTokens.light]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.8),
      ),
      child: child!,
    ),
    home: home,
  );
  if (providers != null && providers.isNotEmpty) {
    app = MultiProvider(providers: providers, child: app);
  }
  return app;
}

void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sample high-risk CallRecordTile fits at 1.8x', (tester) async {
    _usePhone(tester);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CallRecordTile(
              record: sampleHighRiskCall(),
              trailing: const CallMenuPreview(),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Likely scam'), findsOneWidget);
    expect(find.text('+60 11-0000 1234'), findsOneWidget);
  });

  testWidgets('Calls help sheet opens, scrolls and closes at 1.8x', (
    tester,
  ) async {
    _usePhone(tester);
    final tour = TourController(steps: kTourSteps, settings: _FakeSettings());
    addTearDown(tour.dispose);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Calls'),
              actions: [
                HelpButton(
                  title: AppLocalizations.of(context).helpCallsTitle,
                  entries: callsHelpEntries,
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ),
        providers: [ChangeNotifierProvider<TourController>.value(value: tour)],
      ),
    );

    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('What things mean'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    // Scroll to the end of the legend; every entry must lay out cleanly.
    await tester.scrollUntilVisible(
      find.text('Show the app tour again'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsNothing);
  });

  testWidgets('tour bubble fits on every step at 1.8x', (tester) async {
    _usePhone(tester);
    final targets = CoachMarkTargets(kTourTabCount);
    final tour = TourController(steps: kTourSteps, settings: _FakeSettings());
    addTearDown(tour.dispose);

    await tester.pumpWidget(
      _app(
        CoachMarkOverlay(
          controller: tour,
          targets: targets,
          child: Scaffold(
            body: ListView(
              children: [
                // A tall Home status card, so the bubble must share space.
                Container(
                  key: targets.keyFor(TourTarget.homeStatus),
                  height: 360,
                  color: Colors.green,
                ),
              ],
            ),
            bottomNavigationBar: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (var i = 0; i < kTourTabCount; i++)
                    Expanded(
                      child: SizedBox.expand(key: targets.keyForTab(i)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    tour.start();
    for (var i = 0; i < kTourSteps.length; i++) {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
      expect(find.text('${i + 1} of ${kTourSteps.length}'), findsOneWidget);
      if (i < kTourSteps.length - 1) {
        await tester.tap(find.text('Next'));
      }
    }

    // Back goes to the previous step.
    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('${kTourSteps.length - 1} of ${kTourSteps.length}'),
        findsOneWidget);

    // Tapping the scrim does not advance.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('${kTourSteps.length - 1} of ${kTourSteps.length}'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
