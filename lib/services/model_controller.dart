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
    _spec = modelById(await _settings.selectedModelId());
    _manager.spec = _spec;
    await refreshInstalled();
    if (_busy) return;
    if (isBundled) {
      if (!_installed) await installBundled();
    } else if (await ModelStore.exists(_spec)) {
      await _registerPersistent();
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
      if (isBundled) {
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
