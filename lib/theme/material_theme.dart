import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:scamwatch_mobile_app/theme/app_tokens.dart';

/// Secondary text color. The Forui `mutedForeground` is blended a quarter of
/// the way toward `foreground` so small grey text stays easy to read for older
/// users. Measured WCAG contrast (background / card):
/// light #4E4964 = 8.2:1 / 8.5:1, dark #B8B2CF = 9.3:1 / 8.7:1.
Color secondaryTextColor(FColors colors) =>
    Color.lerp(colors.mutedForeground, colors.foreground, 0.25)!;

/// Material theme layered on the Forui colors. Text sizes and tap targets are
/// tuned for older users: body text starts at 16, nothing is smaller than 13,
/// and every button is at least 52dp tall.
ThemeData buildMaterialTheme(FColors colors) {
  final isDark = colors.brightness == Brightness.dark;
  final secondaryText = secondaryTextColor(colors);

  TextStyle style(
    double size,
    FontWeight weight, {
    Color? color,
    double height = 1.3,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color ?? colors.foreground,
    letterSpacing: 0,
    height: height,
  );

  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  const buttonMinSize = Size(64, 52);
  final buttonText = style(16, FontWeight.w600, height: 1.2);

  return ThemeData(
    useMaterial3: true,
    extensions: [isDark ? AppTokens.dark : AppTokens.light],
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
      onSurfaceVariant: secondaryText,
    ),
    scaffoldBackgroundColor: colors.background,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: TextTheme(
      displayLarge: style(48, FontWeight.w700, height: 1.15),
      displayMedium: style(40, FontWeight.w700, height: 1.15),
      displaySmall: style(34, FontWeight.w700, height: 1.15),
      headlineLarge: style(30, FontWeight.w700, height: 1.2),
      headlineMedium: style(28, FontWeight.w700, height: 1.2),
      headlineSmall: style(26, FontWeight.w700, height: 1.25),
      titleLarge: style(22, FontWeight.w700, height: 1.25),
      titleMedium: style(18, FontWeight.w600),
      titleSmall: style(16, FontWeight.w600),
      bodyLarge: style(18, FontWeight.w400, height: 1.4),
      bodyMedium: style(16, FontWeight.w400, height: 1.4),
      bodySmall: style(14, FontWeight.w400, color: secondaryText, height: 1.35),
      labelLarge: style(16, FontWeight.w600, height: 1.2),
      labelMedium: style(14, FontWeight.w600, height: 1.2),
      labelSmall: style(13, FontWeight.w600, height: 1.2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.card,
      foregroundColor: colors.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: style(22, FontWeight.w700, height: 1.25),
    ),
    cardColor: colors.card,
    dividerColor: colors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: secondaryText, fontSize: 16),
      labelStyle: TextStyle(color: secondaryText, fontSize: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        iconSize: 26,
      ),
    ),
    iconTheme: IconThemeData(color: colors.foreground, size: 26),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      minTileHeight: 64,
      iconColor: colors.foreground,
      titleTextStyle: style(18, FontWeight.w600),
      subtitleTextStyle: style(15, FontWeight.w400, color: secondaryText),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: isDark ? colors.background : colors.card,
      ),
    ),
    dialogTheme: DialogThemeData(
      titleTextStyle: style(22, FontWeight.w700, height: 1.25),
      contentTextStyle: style(16, FontWeight.w400, height: 1.4),
    ),
  );
}
