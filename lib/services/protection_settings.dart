import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/model_catalog.dart';
import '../core/notification_record.dart';

class ProtectionSettings {
  static const String _kEnabled = 'protection_enabled';
  static const String _kHistory = 'verdict_history';
  static const String _kThreshold = 'confidence_threshold';
  static const String _kRemoteEndpoint = 'remote_endpoint';
  static const String _kModelId = 'selected_model_id';
  static const String _kHfToken = 'hf_token';
  static const int _maxHistory = 60;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<bool> protectionEnabled() async =>
      await _prefs.getBool(_kEnabled) ?? false;

  Future<void> setProtectionEnabled(bool value) =>
      _prefs.setBool(_kEnabled, value);

  Future<String> selectedModelId() async =>
      await _prefs.getString(_kModelId) ?? modelCatalog.first.id;

  Future<void> setSelectedModelId(String value) =>
      _prefs.setString(_kModelId, value);

  Future<String> hfToken() async => await _prefs.getString(_kHfToken) ?? '';

  Future<void> setHfToken(String value) => _prefs.setString(_kHfToken, value);

  Future<double> confidenceThreshold() async =>
      await _prefs.getDouble(_kThreshold) ?? 0.6;

  Future<void> setConfidenceThreshold(double value) =>
      _prefs.setDouble(_kThreshold, value);

  Future<String> remoteEndpoint() async =>
      await _prefs.getString(_kRemoteEndpoint) ?? '';

  Future<void> setRemoteEndpoint(String value) =>
      _prefs.setString(_kRemoteEndpoint, value);

  Future<List<EvaluatedNotification>> history() async {
    final raw = await _prefs.getStringList(_kHistory) ?? const [];
    final items = <EvaluatedNotification>[];
    for (final entry in raw) {
      try {
        items.add(
          EvaluatedNotification.fromJson(
            jsonDecode(entry) as Map<String, dynamic>,
          ),
        );
      } catch (_) {}
    }
    return items;
  }

  Future<void> addHistory(EvaluatedNotification item) async {
    final raw = await _prefs.getStringList(_kHistory) ?? <String>[];
    raw.insert(0, jsonEncode(item.toJson()));
    while (raw.length > _maxHistory) {
      raw.removeLast();
    }
    await _prefs.setStringList(_kHistory, raw);
  }

  Future<void> clearHistory() => _prefs.remove(_kHistory);
}
