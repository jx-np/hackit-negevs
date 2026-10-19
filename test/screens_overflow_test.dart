import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/screens/settings/widgets/settings_section.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';
import 'package:scamwatch_mobile_app/widgets/ui/empty_state.dart';
import 'package:scamwatch_mobile_app/widgets/ui/risk_badge.dart';
import 'package:scamwatch_mobile_app/widgets/ui/section_header.dart';

/// Pumps [child] on a small phone (360x690) with large text (1.8x) and fails
/// if any layout overflow or other exception is reported.
Future<void> _pumpLarge(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 690);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [AppTokens.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 690),
          textScaler: TextScaler.linear(1.8),
        ),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('EmptyState fits at 1.8x text', (tester) async {
    await _pumpLarge(
      tester,
      EmptyState(
        icon: LucideIcons.inbox,
        title: 'No messages checked yet',
        message: 'Messages we check for you will show up here.',
        action: FilledButton(onPressed: () {}, child: const Text('Check a message')),
      ),
    );
  });

  testWidgets('SectionHeader with trailing fits at 1.8x text', (tester) async {
    await _pumpLarge(
      tester,
      SectionHeader(
        title: 'Recent alerts from your messages',
        caption: 'Messages we flagged as possible scams.',
        trailing: TextButton(onPressed: () {}, child: const Text('Clear all')),
      ),
    );
  });

  testWidgets('RiskBadge fits at 1.8x text in a narrow row', (tester) async {
    await _pumpLarge(
      tester,
      const Row(
        children: [
          Flexible(
            child: RiskBadge(level: RiskLevel.danger, label: 'Likely a scam message'),
          ),
          SizedBox(width: 8),
          Flexible(
            child: RiskBadge(level: RiskLevel.warning, label: 'Be careful with this one'),
          ),
        ],
      ),
    );
  });

  testWidgets('SettingsSection and SettingsRow fit at 1.8x text', (tester) async {
    await _pumpLarge(
      tester,
      SettingsSection(
        title: 'Protection',
        caption: 'Choose how ScamWatch checks your messages.',
        children: [
          SettingsRow(
            leading: const Icon(LucideIcons.shield),
            title: 'Pause protection',
            subtitle: 'Running now',
            trailing: Switch(value: true, onChanged: (_) {}),
            onTap: () {},
          ),
          const SettingsRow(
            leading: Icon(LucideIcons.globe),
            title: 'Language',
            subtitle: 'English',
          ),
        ],
      ),
    );
  });
}
