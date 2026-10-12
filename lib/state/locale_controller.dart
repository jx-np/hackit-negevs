import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locales the app ships translations for. `en` is the base/fallback.
const List<Locale> kAppSupportedLocales = <Locale>[
  Locale('en'),
  Locale('zh'),
  Locale('ta'),
  Locale('ms'),
];

/// Drives [MaterialApp.locale]. A null [locale] means "follow the device
/// default"; a non-null value is a user override persisted to preferences.
class LocaleController extends ChangeNotifier {
  LocaleController({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const String _kLocale = 'app_locale';

  final SharedPreferencesAsync _prefs;

  Locale? _locale;

  /// The active override, or null when following the system locale.
  Locale? get locale => _locale;

  /// True when no explicit override is set (system default in effect).
  bool get isSystemDefault => _locale == null;

  /// Loads any persisted override. Call once during app start-up.
  Future<void> load() async {
    final code = await _prefs.getString(_kLocale);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Sets a specific language override and persists it.
  Future<void> setLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    await _prefs.setString(_kLocale, locale.languageCode);
  }

  /// Clears the override so the app follows the device locale again.
  Future<void> clearLocale() async {
    if (_locale == null) return;
    _locale = null;
    notifyListeners();
    await _prefs.remove(_kLocale);
  }
}
