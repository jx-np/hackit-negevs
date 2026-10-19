import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/permission_step.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/widgets/done_page.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/widgets/model_page.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/widgets/onboarding_action_bar.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/widgets/permission_page.dart';
import 'package:scamwatch_mobile_app/screens/onboarding/widgets/welcome_page.dart';
import 'package:scamwatch_mobile_app/theme/material_theme.dart';
import 'package:scamwatch_mobile_app/theme/theme.dart';

/// Pumps one onboarding page the way OnboardingScreen lays it out (back
/// button row, scrollable page, action bar) on a small 360x690 phone at the
/// largest text size the app allows (1.8x).
Future<void> _pumpPage(
  WidgetTester tester, {
  required Widget Function(PageController controller) page,
  required String primaryLabel,
  String? secondaryLabel,
  String? stepLabel,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 690 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final controller = PageController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...FLocalizations.localizationsDelegates,
      ],
      theme: buildMaterialTheme(lightColors),
      darkTheme: buildMaterialTheme(darkColors),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.8)),
        child: FTheme(
          data: dark ? darkTheme : lightTheme,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              Expanded(child: page(controller)),
              OnboardingActionBar(
                pageCount: OnboardingPermissions.steps.length + 3,
                pageIndex: 2,
                stepLabel: stepLabel,
                primaryLabel: primaryLabel,
                onPrimary: () {},
                secondaryLabel: secondaryLabel,
                onSecondary: secondaryLabel == null ? null : () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('welcome page fits at 1.8x ($mode)', (tester) async {
      await _pumpPage(
        tester,
        dark: dark,
        page: (c) => WelcomePage(controller: c, index: 0),
        primaryLabel: 'Start',
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    for (final step in OnboardingPermissions.steps) {
      for (final status in StepStatus.values) {
        testWidgets(
          'permission page ${step.kind.name}/${status.name} fits at 1.8x '
          '($mode)',
          (tester) async {
            await _pumpPage(
              tester,
              dark: dark,
              page: (c) => PermissionPage(
                controller: c,
                index: 1,
                step: step,
                status: status,
                skipped: status == StepStatus.notGranted,
              ),
              stepLabel: 'Step 8 of 9',
              primaryLabel: 'Open settings',
              secondaryLabel: 'Not now',
            );
            expect(tester.takeException(), isNull);

            // Open the "Why?" detail where there is one; it must still fit.
            final why = find.text('Why?');
            if (why.evaluate().isNotEmpty) {
              await tester.ensureVisible(why);
              await tester.tap(why);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }

    testWidgets('model page states fit at 1.8x ($mode)', (tester) async {
      for (final state in ['idle', 'downloading', 'ready', 'failed']) {
        await _pumpPage(
          tester,
          dark: dark,
          page: (c) => ModelPage(
            controller: c,
            index: 9,
            ready: state == 'ready',
            downloading: state == 'downloading',
            progress: state == 'downloading' ? 42 : -1,
            failed: state == 'failed',
          ),
          stepLabel: 'Step 9 of 9',
          primaryLabel: 'Download (3.0 GB)',
          secondaryLabel: 'Not now',
        );
        expect(tester.takeException(), isNull, reason: state);
      }
    });

    testWidgets('done pages fit at 1.8x ($mode)', (tester) async {
      for (final granted in [8, 3]) {
        await _pumpPage(
          tester,
          dark: dark,
          page: (c) =>
              DonePage(controller: c, index: 10, grantedCount: granted, total: 8),
          primaryLabel: 'Go to the app',
        );
        expect(tester.takeException(), isNull, reason: '$granted of 8');
      }
    });
  }
}
