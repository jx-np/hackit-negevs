import 'package:flutter/material.dart';

/// App-level design tokens layered on top of the Forui-generated theme.
///
/// This is intentionally a SEPARATE layer from the Forui CLI output
/// (`lib/theme/theme.dart` and its part files). Do not fold these into the
/// generated files — regenerating the Forui theme would wipe them out. Instead
/// this [ThemeExtension] is attached to the Material [ThemeData] built in
/// `main.dart`, so every screen can read it via `Theme.of(context)`.
///
/// Usage:
/// ```dart
/// final tokens = context.tokens; // AppTokens
/// Padding(padding: EdgeInsets.all(tokens.space.md), ...);
/// final danger = tokens.risk.danger;
/// ```
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.space,
    required this.radii,
    required this.risk,
    required this.elevation,
  });

  /// 8-point spacing scale. Values: 4, 8, 12, 16, 24, 32, 48, 64, 80, 96.
  final AppSpacing space;

  /// Corner radii for cards, chips, buttons, sheets.
  final AppRadii radii;

  /// Risk-state colors (safe / warning / danger) plus their soft container
  /// and on-container foreground variants. Brightness-aware.
  final AppRiskColors risk;

  /// Soft, tinted elevation shadows. Brightness-aware.
  final AppElevation elevation;

  /// Light theme tokens (trust-forward).
  static const AppTokens light = AppTokens(
    space: AppSpacing.standard,
    radii: AppRadii.standard,
    risk: AppRiskColors.light,
    elevation: AppElevation.light,
  );

  /// Dark theme tokens (trust-forward).
  static const AppTokens dark = AppTokens(
    space: AppSpacing.standard,
    radii: AppRadii.standard,
    risk: AppRiskColors.dark,
    elevation: AppElevation.dark,
  );

  @override
  AppTokens copyWith({
    AppSpacing? space,
    AppRadii? radii,
    AppRiskColors? risk,
    AppElevation? elevation,
  }) {
    return AppTokens(
      space: space ?? this.space,
      radii: radii ?? this.radii,
      risk: risk ?? this.risk,
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      // Spacing and radii are fixed scales; no need to interpolate.
      space: t < 0.5 ? space : other.space,
      radii: t < 0.5 ? radii : other.radii,
      risk: risk.lerp(other.risk, t),
      elevation: elevation.lerp(other.elevation, t),
    );
  }
}

/// 8-point grid spacing scale. All values divisible by 4 or 8.
@immutable
class AppSpacing {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xl2,
    required this.xl3,
    required this.xl4,
    required this.xl5,
    required this.xl6,
  });

  /// 4
  final double xs;

  /// 8
  final double sm;

  /// 12
  final double md;

  /// 16 — default screen/card padding baseline.
  final double lg;

  /// 24 — card internal padding baseline.
  final double xl;

  /// 32
  final double xl2;

  /// 48
  final double xl3;

  /// 64
  final double xl4;

  /// 80 — major section vertical rhythm.
  final double xl5;

  /// 96
  final double xl6;

  static const AppSpacing standard = AppSpacing(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xl2: 32,
    xl3: 48,
    xl4: 64,
    xl5: 80,
    xl6: 96,
  );
}

/// Corner radii.
@immutable
class AppRadii {
  const AppRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  /// 8 — chips, small controls.
  final double sm;

  /// 12 — buttons, inputs.
  final double md;

  /// 16 — cards.
  final double lg;

  /// 24 — sheets, large surfaces.
  final double xl;

  /// 999 — fully rounded pills/badges.
  final double pill;

  static const AppRadii standard = AppRadii(
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    pill: 999,
  );

  BorderRadius get smRadius => BorderRadius.circular(sm);
  BorderRadius get mdRadius => BorderRadius.circular(md);
  BorderRadius get lgRadius => BorderRadius.circular(lg);
  BorderRadius get xlRadius => BorderRadius.circular(xl);
  BorderRadius get pillRadius => BorderRadius.circular(pill);
}

/// Risk-state colors used by badges, chips, verdict cards, and the shield.
///
/// Each state has a strong [safe]/[warning]/[danger] color for icons/text,
/// a soft [*Container] background, and an [on*Container] foreground to use on
/// top of that soft background.
@immutable
class AppRiskColors {
  const AppRiskColors({
    required this.safe,
    required this.safeContainer,
    required this.onSafeContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  final Color safe;
  final Color safeContainer;
  final Color onSafeContainer;

  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Light palette. Greens/ambers/reds keep their semantic hue but their soft
  /// containers are nudged slightly cooler to harmonize with the violet
  /// primary (#6D4AE0) and near-white violet surfaces (#FBFAFF).
  static const AppRiskColors light = AppRiskColors(
    safe: Color(0xFF1E7D52),
    safeContainer: Color(0xFFDDF2E8),
    onSafeContainer: Color(0xFF0A3D27),
    warning: Color(0xFFB7791F),
    warningContainer: Color(0xFFF7EEDA),
    onWarningContainer: Color(0xFF5A3C0A),
    danger: Color(0xFFC74747),
    dangerContainer: Color(0xFFF9E1E4),
    onDangerContainer: Color(0xFF5E1414),
  );

  /// Dark palette. Lighter foregrounds, deep muted containers.
  static const AppRiskColors dark = AppRiskColors(
    safe: Color(0xFF5FD39B),
    safeContainer: Color(0xFF123A2A),
    onSafeContainer: Color(0xFFBFEFD6),
    warning: Color(0xFFE8C06A),
    warningContainer: Color(0xFF3A2E12),
    onWarningContainer: Color(0xFFF6E3B5),
    danger: Color(0xFFFF7A72),
    dangerContainer: Color(0xFF3E1716),
    onDangerContainer: Color(0xFFFFD2CE),
  );

  AppRiskColors lerp(AppRiskColors other, double t) {
    return AppRiskColors(
      safe: Color.lerp(safe, other.safe, t)!,
      safeContainer: Color.lerp(safeContainer, other.safeContainer, t)!,
      onSafeContainer: Color.lerp(onSafeContainer, other.onSafeContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer:
          Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
    );
  }
}

/// Soft, tinted elevation shadows. Match the shadow hue to the surface rather
/// than using pure black/gray.
@immutable
class AppElevation {
  const AppElevation({required this.card, required this.raised});

  /// Resting card shadow.
  final List<BoxShadow> card;

  /// Raised/floating element shadow (sheets, FABs, active items).
  final List<BoxShadow> raised;

  static const AppElevation light = AppElevation(
    card: [
      BoxShadow(
        color: Color(0x14123A33),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    raised: [
      BoxShadow(
        color: Color(0x1F123A33),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );

  static const AppElevation dark = AppElevation(
    card: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    raised: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );

  AppElevation lerp(AppElevation other, double t) {
    return AppElevation(
      card: BoxShadow.lerpList(card, other.card, t) ?? card,
      raised: BoxShadow.lerpList(raised, other.raised, t) ?? raised,
    );
  }
}

/// Convenient access to [AppTokens] from a [BuildContext].
extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
