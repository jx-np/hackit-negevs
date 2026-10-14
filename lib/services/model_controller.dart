import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/model_catalog.dart';
import 'model_manager.dart';
import 'model_store.dart';
import 'protection_settings.dart';

class ModelController extends ChangeNotifier {
  ModelController(this._settings);

  final ProtectionSettings _settings;
  final GemmaModelManager _manager = GemmaModelManager();

  ScamModelSpec _spec = modelCatalog.first;
  bool _installed = false;
  bool _persistent = false;
  bool _busy = false;
  int _progress = -1;
  String _error = '';

  ScamModelSpec get spec => _spec;
  bool get installed => _installed;
  bool get persistent => _persistent;
  bool get busy => _busy;
  int get progress => _progress;
  String get error => _error;
  bool get isBundled => _spec.assetPath != null;

  Future<void> load() async {
    await _settings.hydrateCustomModel();
    _spec = modelById(await _settings.selectedModelId());
    _manager.spec = _spec;
    await refreshInstalled();
    if (_busy) return;
    if (isBundled) {
      if (!_installed) await installBundled();
    } else if (_spec.isBuiltIn) {
      // Built-in models are owned by the OS; there is no app file to register.
    } else if (await ModelStore.exists(_spec)) {
      await _registerPersistent();
    }
  }

  /// Registers a model file that already sits on the device and makes it the
  /// active model. The file is referenced in place — never copied — because a
  /// few gigabytes would not survive a copy through the app cache.
  Future<void> loadFromDevice(
    String path, {
    String name = '',
    int contextTokens = kDefaultCustomModelContext,
    bool thinking = false,
  }) async {
    _busy = true;
    _progress = 0;
    _error = '';
    notifyListeners();
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('That file is no longer on the device. Pick it again.');
      }
      final sizeBytes = await file.length();
      if (sizeBytes < 64 * 1024 * 1024) {
        throw Exception('That file is too small to be a model file.');
      }
      final fileName = path.split(RegExp(r'[\\/]')).last;
      final displayName = name.trim().isEmpty ? fileName : name.trim();
      final spec = buildCustomModelSpec(
        path: path,
        name: displayName,
        contextTokens: contextTokens.clamp(1024, kMaxCustomModelContext),
        thinking: thinking,
        sizeMb: sizeBytes ~/ (1024 * 1024),
      );
      _manager.spec = spec;
      await _manager.registerFromFile(path);
      customModelSpec = spec;
      _spec = spec;
      _installed = true;
      _persistent = true;
      _progress = 100;
      await _settings.setCustomModelPath(path);
      await _settings.setCustomModelName(displayName);
      await _settings.setCustomModelContext(spec.contextTokens);
      await _settings.setCustomModelThinking(thinking);
      await _settings.setSelectedModelId(kCustomModelId);
    } catch (error) {
      _error = friendlyError(error);
      _progress = -1;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Forgets a picked model. The file itself is deliberately left on the
  /// device: it was the user's download, and unbinding it must not cost them
  /// a multi-gigabyte re-download.
  Future<void> clearCustomModel() async {
    _busy = true;
    notifyListeners();
    try {
      final wasActive = _spec.id == kCustomModelId;
      await _settings.clearCustomModel();
      if (wasActive) {
        _spec = modelCatalog.first;
        _manager.spec = _spec;
        await _settings.setSelectedModelId(_spec.id);
        await refreshInstalled();
      }
      _installed = false;
      _progress = -1;
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _registerPersistent() async {
    _busy = true;
    _progress = 0;
    _error = '';
    notifyListeners();
    try {
      final path = await ModelStore.pathFor(_spec);
      if (path == null) throw Exception('Could not locate the stored model');
      await _manager.registerFromFile(path);
      _installed = true;
      _persistent = true;
      _progress = 100;
    } catch (error) {
      _error = friendlyError(error);
      _progress = -1;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> installBundled() async {
    if (!isBundled || _busy) return;
    _busy = true;
    _progress = 0;
    _error = '';
    notifyListeners();
    try {
      await _manager.ensureInstalled(
        onProgress: (value) {
          _progress = value;
          notifyListeners();
        },
      );
      _installed = true;
      _progress = 100;
    } catch (error) {
      _error = friendlyError(error);
      _progress = -1;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshInstalled() async {
    try {
      _installed = await _manager.isInstalled();
    } catch (_) {
      _installed = false;
    }
    notifyListeners();
  }

  Future<void> select(ScamModelSpec spec) async {
    if (spec.id == _spec.id) return;
    _spec = spec;
    _manager.spec = spec;
    _installed = false;
    _progress = -1;
    _error = '';
    notifyListeners();
    await _settings.setSelectedModelId(spec.id);
    await refreshInstalled();
    if (_busy) return;
    if (isBundled) {
      if (!_installed) await installBundled();
    } else if (_spec.isBuiltIn) {
      // Built-in models are prepared by [GemmaModelManager.install].
    } else if (await ModelStore.exists(_spec)) {
      await _registerPersistent();
    }
  }

  Future<bool> download() async {
    _busy = true;
    _progress = 0;
    _persistent = false;
    _error = '';
    notifyListeners();
    try {
      final token = await _settings.hfToken();
      if (isBundled || _spec.isBuiltIn) {
        await _manager.ensureInstalled(onProgress: _report, token: token);
      } else if (await ModelStore.ensureAccess()) {
        final path = await ModelStore.pathFor(_spec);
        final ok = await ModelStore.download(
          _spec,
          onProgress: _report,
          token: token,
        );
        if (!ok || path == null) {
          throw Exception('Download failed. Check your connection.');
        }
        await _manager.registerFromFile(path);
        _persistent = true;
      } else {
        await _manager.download(onProgress: _report, token: token);
      }
      _installed = true;
      _progress = 100;
      return true;
    } catch (error) {
      _persistent = false;
      _error = friendlyError(error);
      _progress = -1;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _report(int value) {
    _progress = value;
    notifyListeners();
  }

  Future<void> delete() async {
    if (_spec.id == kCustomModelId) {
      await clearCustomModel();
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      await _manager.delete();
      if (!isBundled) await ModelStore.remove(_spec);
      _installed = false;
      _progress = -1;
    } catch (error) {
      _error = friendlyError(error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  static String friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('401') || text.contains('403')) {
      return 'This model is gated. Add a HuggingFace token in Settings that has been granted access.';
    }
    if (text.contains('404')) return 'Model URL not found.';
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      return 'No internet connection.';
    }
    return text;
  }
}
