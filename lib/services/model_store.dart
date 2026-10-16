import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/model_catalog.dart';
import 'scamshield_channels.dart';

/// Thrown when a download is deliberately stopped via [DownloadHandle.cancel].
class DownloadCancelled implements Exception {
  const DownloadCancelled();
  @override
  String toString() => 'Download cancelled';
}

/// Thrown when the device does not have enough free space to finish a
/// download. The message is user-facing.
class InsufficientSpace implements Exception {
  const InsufficientSpace(this.neededBytes, this.freeBytes);
  final int neededBytes;
  final int freeBytes;
  @override
  String toString() =>
      'Not enough free space. Need ${_mb(neededBytes)} MB, '
      '${_mb(freeBytes)} MB free.';
  static int _mb(int bytes) => bytes ~/ (1024 * 1024);
}

/// Progress snapshot for a running download. [received] and [total] are byte
/// counts; [total] is 0 when the server did not report a length.
class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});
  final int received;
  final int total;

  /// 0–100, or -1 when the total size is unknown.
  int get percent =>
      total > 0 ? ((received / total) * 100).clamp(0, 100).round() : -1;
}

/// Handle to an in-flight download. Call [cancel] to abort; the backing
/// [ModelStore.download] future then completes with [DownloadCancelled] and
/// the partial `.part` file is kept on disk so the next attempt resumes.
class DownloadHandle {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Stores downloaded models in the app-specific external directory
/// (`Android/data/<pkg>/files`). Android owns that path, so no storage
/// permission is needed, but it is wiped when the app is uninstalled.
class ModelStore {
  static const String _folder = 'models';

  static Future<Directory?> directory() async {
    if (!Platform.isAndroid) return null;
    try {
      final base = await ScamShieldChannels.storage
          .invokeMethod<String>('getAppModelsDir');
      if (base == null || base.isEmpty) return null;
      final dir = Directory('$base${Platform.pathSeparator}$_folder');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> pathFor(ScamModelSpec spec) async {
    final picked = spec.filePath;
    if (picked != null) return picked;
    final dir = await directory();
    if (dir == null) return null;
    return '${dir.path}${Platform.pathSeparator}${spec.fileName}';
  }

  /// A fully downloaded model must match its expected size (within a small
  /// tolerance for servers that under-report). A half-written file fails here,
  /// so a crashed download never looks "installed".
  static Future<bool> exists(ScamModelSpec spec) async {
    final path = await pathFor(spec);
    if (path == null) return false;
    final file = File(path);
    if (!await file.exists()) return false;
    final len = await file.length();
    if (len < 1024 * 1024) return false;
    // Picked files have no expected size we control — trust the pick.
    if (spec.filePath != null) return true;
    final expected = spec.approxSizeMb * 1024 * 1024;
    if (expected <= 0) return true;
    // Allow 15% slack: approxSizeMb is a catalog estimate, not exact.
    return len >= (expected * 0.85).round();
  }

  /// A picked file belongs to the user, never to this app, so it is left on
  /// disk. Clearing the pick happens in [ModelController.clearCustomModel].
  static Future<bool> remove(ScamModelSpec spec) async {
    if (spec.filePath != null) return false;
    final path = await pathFor(spec);
    if (path == null) return false;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final part = File('$path.part');
      if (await part.exists()) await part.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Downloads [spec] to the app models directory with resume, a free-space
  /// pre-check, and a final size check. Returns true on success. Throws
  /// [DownloadCancelled], [InsufficientSpace], or rethrows HTTP/IO errors so
  /// the caller can surface a real message instead of a bare false.
  static Future<bool> download(
    ScamModelSpec spec, {
    void Function(DownloadProgress progress)? onProgress,
    String? token,
    DownloadHandle? handle,
  }) async {
    if (spec.filePath != null) return false;
    final path = await pathFor(spec);
    if (path == null) {
      throw Exception('Could not resolve a storage path for the model.');
    }
    final part = File('$path.part');
    final client = http.Client();
    IOSink? sink;
    try {
      // Resume from whatever is already on disk.
      var existing = 0;
      if (await part.exists()) {
        existing = await part.length();
      }

      final request = http.Request('GET', Uri.parse(spec.url));
      final trimmed = (token ?? '').trim();
      if (trimmed.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $trimmed';
      }
      if (existing > 0) {
        request.headers['Range'] = 'bytes=$existing-';
      }

      final response = await client.send(request);
      final status = response.statusCode;
      final resuming = status == 206;
      if (status != 200 && status != 206) {
        // A 416 means the .part is already complete or stale — start clean.
        if (status == 416 && existing > 0) {
          await part.delete();
          client.close();
          return await download(
            spec,
            onProgress: onProgress,
            token: token,
            handle: handle,
          );
        }
        throw http.ClientException('HTTP $status while downloading model.');
      }

      // If the server ignored the Range header, restart from zero.
      if (existing > 0 && !resuming) existing = 0;

      final remaining = response.contentLength ?? 0;
      final total = resuming && remaining > 0
          ? existing + remaining
          : (remaining > 0 ? remaining : spec.approxSizeMb * 1024 * 1024);

      await _ensureFreeSpace(path, total - existing);

      final out = part.openWrite(mode: resuming ? FileMode.append : FileMode.write);
      sink = out;
      if (!resuming) existing = 0;
      var received = existing;
      onProgress?.call(DownloadProgress(received: received, total: total));
      await for (final chunk in response.stream) {
        if (handle?.isCancelled ?? false) {
          await out.flush();
          await out.close();
          sink = null;
          throw const DownloadCancelled();
        }
        out.add(chunk);
        received += chunk.length;
        onProgress?.call(DownloadProgress(received: received, total: total));
      }
      await out.flush();
      await out.close();
      sink = null;

      // Integrity: a truncated download must not be promoted to the final name.
      final got = await part.length();
      if (total > 0 && got < (total * 0.85).round()) {
        throw http.ClientException(
          'Download incomplete: got $got of $total bytes.',
        );
      }

      final file = File(path);
      if (await file.exists()) await file.delete();
      await part.rename(path);
      return true;
    } catch (error) {
      try {
        await sink?.close();
      } catch (_) {}
      // Keep the .part on cancel so the next run resumes; drop it on hard
      // failures that would otherwise leave a corrupt partial behind.
      if (error is! DownloadCancelled && error is! InsufficientSpace) {
        debugPrint('[ModelStore] download of ${spec.id} failed: $error');
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Verifies the model directory's filesystem has room for [needed] bytes
  /// plus a 200 MB safety margin. Throws [InsufficientSpace] if not.
  static Future<void> _ensureFreeSpace(String path, int needed) async {
    if (needed <= 0) return;
    try {
      final free = await _freeBytesFor(path);
      if (free <= 0) return; // Could not determine — don't block the download.
      final margin = 200 * 1024 * 1024;
      if (free < needed + margin) {
        throw InsufficientSpace(needed, free);
      }
    } on InsufficientSpace {
      rethrow;
    } catch (_) {
      // Statvfs unavailable — fail open rather than block a valid download.
    }
  }

  static Future<int> _freeBytesFor(String path) async {
    final dir = File(path).parent.path;
    try {
      final result = await Process.run('df', ['-k', dir]);
      if (result.exitCode != 0) return 0;
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length < 2) return 0;
      final cols = lines.last.trim().split(RegExp(r'\s+'));
      // df -k columns: Filesystem 1K-blocks Used Available ... (Available = [3])
      if (cols.length < 4) return 0;
      final availKb = int.tryParse(cols[3]) ?? 0;
      return availKb * 1024;
    } catch (_) {
      return 0;
    }
  }

  /// Looks for model files the user has put inside the app models directory.
  /// The all-files permission is gone, so shared-storage scanning is no longer
  /// possible; this now only reports files the app itself can read.
  static Future<List<FoundModelFile>> scanForModels({
    int limit = 60,
  }) async {
    if (!Platform.isAndroid) return const [];
    final dir = await directory();
    if (dir == null) return const [];
    final found = <String, FoundModelFile>{};
    try {
      await _scan(dir, found, limit);
    } catch (error) {
      debugPrint('[ModelStore] scan of ${dir.path} failed: $error');
    }
    final list = found.values.toList()
      ..sort((a, b) => b.sizeMb.compareTo(a.sizeMb));
    debugPrint('[ModelStore] scan found ${list.length} model file(s)');
    return list.take(limit).toList();
  }

  static Future<void> _scan(
    Directory dir,
    Map<String, FoundModelFile> found,
    int limit,
  ) async {
    if (found.length >= limit) return;
    final Stream<FileSystemEntity> entries;
    try {
      entries = dir.list(followLinks: false);
    } catch (error) {
      debugPrint('[ModelStore] cannot list ${dir.path}: $error');
      return;
    }
    await for (final entry in entries) {
      if (found.length >= limit) return;
      if (entry is! File) continue;
      final path = entry.path;
      if (path.toLowerCase().endsWith('.part')) continue;
      final lower = path.toLowerCase();
      final isModel = lower.endsWith('.litertlm') || lower.endsWith('.task');
      if (!isModel) continue;
      try {
        final size = await entry.length();
        if (size < 64 * 1024 * 1024) continue;
        found[path] = FoundModelFile(path: path, sizeMb: size ~/ (1024 * 1024));
      } catch (_) {}
    }
  }
}

class FoundModelFile {
  FoundModelFile({required this.path, required this.sizeMb});

  final String path;
  final int sizeMb;

  String get fileName => path.split(RegExp(r'[\\/]')).last;
}
