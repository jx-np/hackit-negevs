/// The app's single type scale.
///
/// Both the Material [TextTheme] (see `material_theme.dart`) and the Forui
/// typography (see the generated `typography.dart`) are built from these
/// values. Screens must use the theme's text styles instead of hardcoding a
/// `fontSize`, so changing a size here updates the whole app.
///
/// Older-user readability rule: nothing renders below [xs] (currently 18sp).
abstract final class AppTypeScale {
  // T-shirt scale, reused by both theme systems.
  static const double xs = 18;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 26;
  static const double xl = 28;
  static const double xl2 = 32;
  static const double xl3 = 34;
  static const double xl4 = 40;
  static const double xl5 = 48;
  static const double xl6 = 60;
  static const double xl7 = 72;
  static const double xl8 = 96;

  // Semantic names used by the Material text theme.
  static const double caption = xs;
  static const double label = xs;
  static const double body = sm;
  static const double bodyLarge = md;
  static const double titleSmall = xs;
  static const double title = md;
  static const double titleLarge = lg;
  static const double headlineSmall = xl;
  static const double headline = xl2;
  static const double headlineLarge = xl3;
  static const double displaySmall = xl3;
  static const double displayMedium = xl4;
  static const double displayLarge = xl5;
}
