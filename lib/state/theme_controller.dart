import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives [MaterialApp.themeMode]. [ThemeMode.system] follows the device
/// light/dark setting; [ThemeMode.light] and [ThemeMode.dark] are explicit
/// user overrides persisted to preferences.
class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const String _kThemeMode = 'app_theme_mode';

  final SharedPreferencesAsync _prefs;

  ThemeMode _mode = ThemeMode.system;

  /// The active theme mode. Defaults to [ThemeMode.system].
  ThemeMode get mode => _mode;

  /// True when following the device light/dark setting.
  bool get isSystemDefault => _mode == ThemeMode.system;

  /// Loads any persisted override. Call once during app start-up.
  Future<void> load() async {
    final stored = await _prefs.getString(_kThemeMode);
    final mode = _parse(stored);
    if (mode != _mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  /// Sets the theme mode and persists it.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_kThemeMode, mode.name);
  }

  static ThemeMode _parse(String? name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
