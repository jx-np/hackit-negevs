// Temporary: renders Safety hero previews to PNG. Delete after review.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:scamwatch_mobile_app/l10n/app_localizations.dart';
import 'package:scamwatch_mobile_app/screens/safety/widgets/safety_hero.dart';
import 'package:scamwatch_mobile_app/theme/theme.dart';
import 'package:scamwatch_mobile_app/theme/material_theme.dart';

final _out = '${Directory.systemTemp.path}\\hero_preview';
const _fonts = r'D:\flutter\bin\cache\artifacts\material_fonts';

Future<void> _loadFonts() async {
  ByteData read(String f) =>
      ByteData.sublistView(Uint8List.fromList(File('$_fonts\\$f').readAsBytesSync()));
  final roboto = FontLoader('Roboto')
    ..addFont(Future.value(read('roboto-regular.ttf')))
    ..addFont(Future.value(read('roboto-medium.ttf')))
    ..addFont(Future.value(read('roboto-bold.ttf')));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(read('materialicons-regular.otf')));
  await icons.load();
}

// Button and app bar styles have no font family, which falls back to the
// blocky test font. On a device they use the system font.
ThemeData _withRoboto(ThemeData t) {
  final button = t.filledButtonTheme.style!;
  final label = button.textStyle!.resolve({})!.copyWith(fontFamily: 'Roboto');
  return t.copyWith(
    appBarTheme: t.appBarTheme.copyWith(
      titleTextStyle: t.appBarTheme.titleTextStyle!.copyWith(fontFamily: 'Roboto'),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: button.copyWith(textStyle: WidgetStatePropertyAll(label)),
    ),
  );
}

Future<void> _render(
  WidgetTester tester, {
  required String name,
  required FColors colors,
  SafetyHeroStatus status = SafetyHeroStatus.on,
}) async {
  const size = Size(412, 860);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  final on = status == SafetyHeroStatus.on;

  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _withRoboto(buildMaterialTheme(colors)),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: size, disableAnimations: true),
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final theme = Theme.of(context);
              return Scaffold(
                appBar: AppBar(title: Text(l10n.safetyTitle)),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SafetyHero(
                      status: status,
                      title: on ? l10n.safetyProtectedOn : l10n.safetyProtectedOff,
                      subtitle: on ? l10n.safetyHeroOnBody : l10n.safetyTurnOnToCheck,
                      action: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(60),
                          ),
                          onPressed: () {},
                          icon: Icon(on ? Icons.toggle_on : Icons.toggle_off, size: 28),
                          label: Text(on ? l10n.safetyTurnOff : l10n.safetyTurnOn),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.safetyRecentAlerts, style: theme.textTheme.titleLarge),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out\\$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('dark on', (t) =>
      _render(t, name: 'dark_on', colors: darkColors));
  testWidgets('light on', (t) =>
      _render(t, name: 'light_on', colors: lightColors));
  testWidgets('dark off', (t) => _render(t,
      name: 'dark_off', colors: darkColors, status: SafetyHeroStatus.off));
  testWidgets('light off', (t) => _render(t,
      name: 'light_off', colors: lightColors, status: SafetyHeroStatus.off));
}
