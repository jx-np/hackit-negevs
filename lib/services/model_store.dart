import 'dart:io';

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

  static Future<bool> remove(ScamModelSpec spec) async {
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
}
