import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../core/model_catalog.dart';
import 'scamshield_channels.dart';

/// Stores downloaded models in the device's public Downloads folder so they
/// survive an uninstall/reinstall. `flutter_gemma`'s own storage lives in the
/// app-private directory, which Android deletes on uninstall.
class ModelStore {
  static const String _folder = 'ScamShield';

  static Future<bool> hasAccess() async {
    if (!Platform.isAndroid) return false;
    if (await Permission.manageExternalStorage.isGranted) return true;
    return Permission.storage.isGranted;
  }

  static Future<bool> ensureAccess() async {
    if (!Platform.isAndroid) return false;
    if (await hasAccess()) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;
    return Permission.storage.request().isGranted;
  }

  static Future<Directory?> directory() async {
    if (!Platform.isAndroid) return null;
    try {
      final base = await ScamShieldChannels.storage
          .invokeMethod<String>('getPublicDownloadsDir');
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

  static Future<bool> exists(ScamModelSpec spec) async {
    final path = await pathFor(spec);
    if (path == null) return false;
    final file = File(path);
    if (!await file.exists()) return false;
    return await file.length() > 1024 * 1024;
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
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> download(
    ScamModelSpec spec, {
    void Function(int progress)? onProgress,
    String? token,
  }) async {
    if (spec.filePath != null) return false;
    final path = await pathFor(spec);
    if (path == null) return false;
    final target = File('$path.part');
    final client = http.Client();
    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse(spec.url));
      final trimmed = (token ?? '').trim();
      if (trimmed.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $trimmed';
      }
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final total =
          response.contentLength ?? (spec.approxSizeMb * 1024 * 1024);
      sink = target.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(
            ((received / total) * 100).clamp(0, 100).round(),
          );
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      final file = File(path);
      if (await file.exists()) await file.delete();
      await target.rename(path);
      return true;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (await target.exists()) await target.delete();
      } catch (_) {}
      return false;
    } finally {
      client.close();
    }
  }

  /// Looks for model files the user has put on the device. The manifest
  /// already grants `MANAGE_EXTERNAL_STORAGE`, so the file can be handed to
  /// `FlutterGemma.installModel(...).fromFile(path)` in place — no copy, no
  /// content-URI shim (both would be fatal for a multi-gigabyte model).
  static Future<List<FoundModelFile>> scanForModels({
    int maxDepth = 3,
    int limit = 60,
  }) async {
    if (!Platform.isAndroid) return const [];
    await ensureAccess();
    // Each root is scanned on its own: the shared storage root contains
    // directories the app may not read (Android/data), and one rejection
    // must not throw away files already found elsewhere.
    final roots = <(String, int)>[
      ('/storage/emulated/0/Download', maxDepth),
      ('/storage/emulated/0/Documents', maxDepth),
      ('/storage/emulated/0', 2),
    ];
    final found = <String, FoundModelFile>{};
    for (final (path, depth) in roots) {
      try {
        await _scan(Directory(path), found, 1, depth, limit);
      } catch (error) {
        debugPrint('[ModelStore] scan of $path failed: $error');
      }
      if (found.length >= limit) break;
    }
    final list = found.values.toList()
      ..sort((a, b) => b.sizeMb.compareTo(a.sizeMb));
    debugPrint('[ModelStore] scan found ${list.length} model file(s)');
    return list.take(limit).toList();
  }

  static Future<void> _scan(
    Directory dir,
    Map<String, FoundModelFile> found,
    int depth,
    int maxDepth,
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
    try {
      await for (final entry in entries) {
        if (found.length >= limit) return;
        if (entry is Directory) {
          final name = entry.path.split(RegExp(r'[\\/]')).last;
          if (name.startsWith('.')) continue;
          if (depth < maxDepth) {
            await _scan(entry, found, depth + 1, maxDepth, limit);
          }
          continue;
        }
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
    } catch (error) {
      debugPrint('[ModelStore] listing stopped in ${dir.path}: $error');
    }
  }
}

class FoundModelFile {
  FoundModelFile({required this.path, required this.sizeMb});

  final String path;
  final int sizeMb;

  String get fileName => path.split(RegExp(r'[\\/]')).last;
}
