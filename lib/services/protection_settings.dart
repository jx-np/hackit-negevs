import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/model_catalog.dart';
import '../core/notification_record.dart';

/// Default cloud review endpoint. It is an OpenAI-compatible
/// `/v1/chat/completions` server; the value can be overridden in Settings.
const String kDefaultRemoteEndpoint =
    'https://e1c1-2406-3003-2002-f85-b013-9ac9-d484-6998.ngrok-free.app/v1/chat/completions';

/// Default bearer token for the cloud review endpoint.
const String kDefaultRemoteApiKey = 'sk-lm-CZ4xaYYQ:L14H7rrwAz3LdE2zxJ5E';

/// Default cloud model. It is a reasoning model, so it also gets a
/// reasoning-token budget.
const String kDefaultRemoteModel = 'minicpm5-2b';

/// Default cap on the model's private reasoning tokens.
const int kDefaultReasoningBudget = 512;

/// Default cap on generated tokens per cloud request. 0 means automatic: the
/// reasoning budget plus a fixed answer allowance.
const int kDefaultRemoteMaxTokens = 0;

/// Default context window used when the user picks a model file off the
/// device. MiniCPM5-2B supports up to 131072 tokens, but each token of KV
/// cache costs real RAM, so 8192 is a safe starting point that can be raised
/// from the Model tab once the device tolerates it.
const int kDefaultCustomModelContext = 8192;

/// Largest context window that can be requested for a picked model. Matches
/// MiniCPM5-2B's native context length; the converted file may bake in a
/// smaller `kv_cache_max_len`, in which case the runtime clamps it.
const int kMaxCustomModelContext = 131072;

/// Hardware backend the on-device model runs on. CPU works on every device;
/// GPU is faster on phones with a supported GPU but can fail to initialise on
/// some hardware, in which case the engine falls back automatically.
enum ModelBackend { cpu, gpu, npu, npuTest }

/// Ask LiteRT-LM to try NPU, then GPU, then CPU when available.
const ModelBackend kDefaultModelBackend = ModelBackend.npu;

class ProtectionSettings {
  static const String _kEnabled = 'protection_enabled';
  static const String _kHistory = 'verdict_history';
  static const String _kThreshold = 'confidence_threshold';
  static const String _kRemoteEndpoint = 'remote_endpoint';
  static const String _kRemoteApiKey = 'remote_api_key';
  static const String _kRemoteModel = 'remote_model';
  static const String _kReasoningBudget = 'reasoning_budget';
  static const String _kRemoteMaxTokens = 'remote_max_tokens';
  static const String _kForceCloud = 'force_cloud';
  static const String _kModelId = 'selected_model_id';
  static const String _kHfToken = 'hf_token';
  static const String _kCustomPath = 'custom_model_path';
  static const String _kCustomName = 'custom_model_name';
  static const String _kCustomContext = 'custom_model_context';
  static const String _kCustomThinking = 'custom_model_thinking';
  static const String _kModelBackend = 'model_backend';
  static const String _kProtectionSetupComplete = 'protection_setup_complete';
  static const String _kSeenTutorial = 'seen_tutorial';
  static const int _maxHistory = 60;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<bool> protectionEnabled() async =>
      await _prefs.getBool(_kEnabled) ?? false;

  Future<void> setProtectionEnabled(bool value) =>
      _prefs.setBool(_kEnabled, value);

    Future<bool> protectionSetupComplete() async =>
      await _prefs.getBool(_kProtectionSetupComplete) ?? false;

    Future<void> setProtectionSetupComplete(bool value) =>
      _prefs.setBool(_kProtectionSetupComplete, value);

  Future<bool> seenTutorial() async =>
      await _prefs.getBool(_kSeenTutorial) ?? false;

  Future<void> setSeenTutorial(bool value) =>
      _prefs.setBool(_kSeenTutorial, value);

  Future<String> selectedModelId() async =>
      await _prefs.getString(_kModelId) ?? modelCatalog.first.id;

  Future<void> setSelectedModelId(String value) =>
      _prefs.setString(_kModelId, value);

  /// Hardware backend the on-device model should run on. Stored as the enum
  /// name so an unknown or legacy value falls back to the safe CPU default.
  Future<ModelBackend> modelBackend() async {
    final stored = await _prefs.getString(_kModelBackend);
    if (stored == ModelBackend.npuTest.name && !kDebugMode) {
      return kDefaultModelBackend;
    }
    return ModelBackend.values.firstWhere(
      (backend) => backend.name == stored,
      orElse: () => kDefaultModelBackend,
    );
  }

  Future<void> setModelBackend(ModelBackend value) =>
      _prefs.setString(_kModelBackend, value.name);

  Future<String> customModelPath() async =>
      await _prefs.getString(_kCustomPath) ?? '';

  Future<void> setCustomModelPath(String value) =>
      _prefs.setString(_kCustomPath, value);

  Future<String> customModelName() async =>
      await _prefs.getString(_kCustomName) ?? '';

  Future<void> setCustomModelName(String value) =>
      _prefs.setString(_kCustomName, value);

  Future<int> customModelContext() async =>
      await _prefs.getInt(_kCustomContext) ?? kDefaultCustomModelContext;

  Future<void> setCustomModelContext(int value) =>
      _prefs.setInt(_kCustomContext, value);

  Future<bool> customModelThinking() async =>
      await _prefs.getBool(_kCustomThinking) ?? false;

  Future<void> setCustomModelThinking(bool value) =>
      _prefs.setBool(_kCustomThinking, value);

  /// Rebuilds [customModelSpec] from storage so `modelById` can resolve the
  /// custom entry. Must run before any `modelById(...)` call, otherwise an
  /// unknown id would silently fall back to the first catalog model.
  Future<void> hydrateCustomModel() async {
    final path = await customModelPath();
    if (path.isEmpty) {
      clearCustomModelSpec();
      return;
    }
    final file = File(path);
    int sizeMb = 0;
    try {
      if (await file.exists()) {
        sizeMb = await file.length() ~/ (1024 * 1024);
      }
    } catch (_) {}
    customModelSpec = buildCustomModelSpec(
      path: path,
      name: await customModelName(),
      contextTokens: await customModelContext(),
      thinking: await customModelThinking(),
      sizeMb: sizeMb,
    );
  }

  Future<void> clearCustomModel() async {
    clearCustomModelSpec();
    await _prefs.remove(_kCustomPath);
    await _prefs.remove(_kCustomName);
    await _prefs.remove(_kCustomContext);
    await _prefs.remove(_kCustomThinking);
  }

  Future<String> hfToken() async => await _prefs.getString(_kHfToken) ?? '';

  Future<void> setHfToken(String value) => _prefs.setString(_kHfToken, value);

  Future<double> confidenceThreshold() async =>
      await _prefs.getDouble(_kThreshold) ?? 0.6;

  Future<void> setConfidenceThreshold(double value) =>
      _prefs.setDouble(_kThreshold, value);

  Future<String> remoteEndpoint() async =>
      await _prefs.getString(_kRemoteEndpoint) ?? kDefaultRemoteEndpoint;

  Future<void> setRemoteEndpoint(String value) =>
      _prefs.setString(_kRemoteEndpoint, value);

  Future<String> remoteApiKey() async =>
      await _prefs.getString(_kRemoteApiKey) ?? kDefaultRemoteApiKey;

  Future<void> setRemoteApiKey(String value) =>
      _prefs.setString(_kRemoteApiKey, value);

  Future<String> remoteModel() async =>
      await _prefs.getString(_kRemoteModel) ?? kDefaultRemoteModel;

  Future<void> setRemoteModel(String value) =>
      _prefs.setString(_kRemoteModel, value);

  Future<int> reasoningBudget() async =>
      await _prefs.getInt(_kReasoningBudget) ?? kDefaultReasoningBudget;

  Future<void> setReasoningBudget(int value) =>
      _prefs.setInt(_kReasoningBudget, value);

  /// Total generated tokens allowed per cloud request. 0 = automatic
  /// (reasoning budget plus the answer allowance).
  Future<int> remoteMaxTokens() async =>
      await _prefs.getInt(_kRemoteMaxTokens) ?? kDefaultRemoteMaxTokens;

  Future<void> setRemoteMaxTokens(int value) =>
      _prefs.setInt(_kRemoteMaxTokens, value);

  /// When true the cloud model is used for every message and the on-device
  /// model is skipped (falling back to it only if the cloud is unreachable).
  Future<bool> forceCloud() async =>
      await _prefs.getBool(_kForceCloud) ?? false;

  Future<void> setForceCloud(bool value) => _prefs.setBool(_kForceCloud, value);

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
