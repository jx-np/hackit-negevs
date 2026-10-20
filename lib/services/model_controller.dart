import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai_builtin_ai/flutter_edge_ai_builtin_ai.dart';

import '../core/model_catalog.dart';
import 'model_manager.dart';
import 'model_store.dart';
import 'protection_settings.dart';

class ModelController extends ChangeNotifier {
  ModelController(this._settings);

  final ProtectionSettings _settings;
  final GemmaModelManager _manager = GemmaModelManager();

  ScamModelSpec _spec = defaultModel;
  bool _installed = false;
  bool _persistent = false;
  bool _busy = false;
  int _progress = -1;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String _error = '';
  DownloadHandle? _downloadHandle;

  /// Whether the OS built-in model (Gemini Nano via AICore) can run on this
  /// device. Null until [probeBuiltInAvailability] has resolved; the settings
  /// UI treats null and false alike (the AICore option stays greyed out) and
  /// lights the option up only once this flips to true.
  bool? _builtInAvailable;

  /// Progress updates arrive once per network chunk — thousands per second on
  /// a fast link. Rebuilding the widget tree that often steals CPU from the
  /// download itself and janks the UI, so progress notifications are coalesced
  /// to at most one every [_progressThrottle]; the terminal frame is flushed.
  static const Duration _progressThrottle = Duration(milliseconds: 120);
  DateTime _lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);

  ScamModelSpec get spec => _spec;
  bool get installed => _installed;
  bool get persistent => _persistent;
  bool get busy => _busy;
  int get progress => _progress;
  String get error => _error;

  /// Bytes received so far for the running file download, or 0 when unknown.
  int get receivedBytes => _receivedBytes;

  /// Total bytes expected for the running file download, or 0 when unknown.
  int get totalBytes => _totalBytes;
  bool get isBundled => _spec.assetPath != null;

  /// True while a cancellable file download is running.
  bool get canCancel => _downloadHandle != null;

  /// True when the OS built-in model (Gemini Nano via AICore) is usable on this
  /// device. False both before the probe has run and when the device cannot run
  /// it, so callers can gate the AICore option on this single flag.
  bool get builtInAvailable => _builtInAvailable ?? false;

  /// True once [probeBuiltInAvailability] has resolved at least once, so the UI
  /// can tell "still checking" apart from "checked, not available".
  bool get builtInProbed => _builtInAvailable != null;

  /// Probes the OS for built-in model (AICore) support. Availability is a
  /// runtime property — a device may gain it after an OS update or lose it when
  /// the user disables the feature — so this is safe to call again to refresh.
  /// [BuiltInAi.availability] never throws and never hangs; anything other than
  /// [BuiltInAiAvailability.available] (unsupported device, not-yet-downloaded,
  /// disabled) leaves the option greyed out.
  Future<void> probeBuiltInAvailability() async {
    final availability = await BuiltInAi.availability();
    final available = availability == BuiltInAiAvailability.available;
    // Notify on the first probe (null -> bool) so the UI can stop showing a
    // "checking" state, and on any later change (device gained/lost support).
    if (_builtInAvailable == available) return;
    _builtInAvailable = available;
    notifyListeners();
  }

  /// Aborts the running download. The partial file is kept so a later retry
  /// resumes from where it stopped.
  void cancelDownload() => _downloadHandle?.cancel();

  Future<void> load() async {
    await _settings.hydrateCustomModel();
    _spec = modelById(await _settings.selectedModelId());
    _manager.spec = _spec;
    // Probe AICore support in the background; the model load below must not
    // wait on it, and the probe notifies listeners itself when it resolves.
    unawaited(probeBuiltInAvailability());
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
        _spec = defaultModel;
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
      if (!_installed) await download();
    } else if (await ModelStore.exists(_spec)) {
      await _registerPersistent();
    }
  }

  Future<bool> download() async {
    _busy = true;
    _progress = 0;
    _receivedBytes = 0;
    _totalBytes = 0;
    _persistent = false;
    _error = '';
    notifyListeners();
    try {
      final token = await _settings.hfToken();
      if (isBundled || _spec.isBuiltIn) {
        await _manager.ensureInstalled(onProgress: _report, token: token);
      } else {
        final path = await ModelStore.pathFor(_spec);
        if (path == null) {
          throw Exception('Could not resolve a storage path for the model.');
        }
        _downloadHandle = DownloadHandle();
        final ok = await ModelStore.download(
          _spec,
          onProgress: _reportBytes,
          token: token,
          handle: _downloadHandle,
        );
        if (!ok) {
          throw Exception('Download failed. Check your connection.');
        }
        await _manager.registerFromFile(path);
        _persistent = true;
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
      _downloadHandle = null;
      _receivedBytes = 0;
      _totalBytes = 0;
      _busy = false;
      notifyListeners();
    }
  }

  /// Selects [spec] and downloads it through the flutter_edge_ai plugin's
  /// foreground path (`fromNetwork(..., foreground: true)` inside
  /// [GemmaModelManager.install]). Unlike [download], which uses a pure-Dart
  /// HTTP fetch for catalog models, this routes every model type through the
  /// plugin so the native progress notification shows, the transfer survives
  /// navigation, and the file lands in app-internal storage managed by the
  /// plugin.
  ///
  /// The spec is selected (and its id persisted) first so the background
  /// isolate loads this exact model on the next syncSettings. Returns true on
  /// success. ensureInstalled is a no-op when the file is already present.
  Future<bool> downloadViaPlugin(ScamModelSpec spec) async {
    // Persist the selection up front; select() also refreshes `installed` and
    // may early-return a bundled install, which is fine for the no-op case.
    if (spec.id != _spec.id) {
      _spec = spec;
      _manager.spec = spec;
      await _settings.setSelectedModelId(spec.id);
    }
    _busy = true;
    _progress = 0;
    _receivedBytes = 0;
    _totalBytes = 0;
    _persistent = false;
    _error = '';
    notifyListeners();
    try {
      final token = await _settings.hfToken();
      // ensureInstalled is a no-op when the file is already present; otherwise
      // install() runs the foreground fromNetwork/fromAsset/builtIn path.
      await _manager.ensureInstalled(onProgress: _report, token: token);
      _installed = true;
      _persistent = !isBundled && !_spec.isBuiltIn;
      _progress = 100;
      return true;
    } catch (error) {
      _persistent = false;
      _error = friendlyError(error);
      _progress = -1;
      return false;
    } finally {
      _receivedBytes = 0;
      _totalBytes = 0;
      _busy = false;
      notifyListeners();
    }
  }

  void _report(int value) {
    _progress = value;
    _notifyThrottled(flush: value >= 100 || value < 0);
  }

  void _reportBytes(DownloadProgress p) {
    _receivedBytes = p.received;
    _totalBytes = p.total;
    _progress = p.percent;
    final done = p.total > 0 && p.received >= p.total;
    _notifyThrottled(flush: done || p.percent >= 100);
  }

  /// Fires [notifyListeners] at most once per [_progressThrottle], unless
  /// [flush] forces it (used for the terminal 0%/100% frames so the bar never
  /// freezes just short of done).
  void _notifyThrottled({bool flush = false}) {
    final now = DateTime.now();
    if (!flush && now.difference(_lastProgressAt) < _progressThrottle) return;
    _lastProgressAt = now;
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
    if (error is DownloadCancelled) return 'Download cancelled.';
    if (error is InsufficientSpace) {
      final needMb = error.neededBytes ~/ (1024 * 1024);
      final freeMb = error.freeBytes ~/ (1024 * 1024);
      return 'Not enough storage. This model needs about $needMb MB '
          'but only $freeMb MB is free.';
    }
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
