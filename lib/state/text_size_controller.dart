import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app text size choices, on top of the device's own font-size setting.
///
/// The app already starts from a large base type scale, so these steps are
/// deliberately modest: each one is a visible bump without wrecking layouts.
enum AppTextSize {
  normal(1.0),
  large(1.15),
  extraLarge(1.3);

  const AppTextSize(this.factor);

  /// Multiplier applied on top of the system text scale.
  final double factor;

  static AppTextSize parse(String? name) => AppTextSize.values.firstWhere(
    (size) => size.name == name,
    orElse: () => AppTextSize.normal,
  );
}

/// Persists the user's in-app text size and rebuilds the app when it changes.
///
/// The effective scale is `system scale * [AppTextSize.factor]`, clamped in
/// `main.dart` so extreme combinations stay readable instead of overflowing.
class TextSizeController extends ChangeNotifier {
  TextSizeController({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String _kTextSize = 'app_text_size';

  final SharedPreferencesAsync _prefs;

  AppTextSize _size = AppTextSize.normal;

  AppTextSize get size => _size;

  /// Loads any persisted choice. Call once during app start-up.
  Future<void> load() async {
    final stored = await _prefs.getString(_kTextSize);
    final size = AppTextSize.parse(stored);
    if (size != _size) {
      _size = size;
      notifyListeners();
    }
  }

  /// Sets the text size and persists it.
  Future<void> setSize(AppTextSize size) async {
    if (_size == size) return;
    _size = size;
    notifyListeners();
    await _prefs.setString(_kTextSize, size.name);
  }
}
