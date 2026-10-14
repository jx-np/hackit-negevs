import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_builtin_ai/flutter_edge_ai_builtin_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';

import '../core/model_catalog.dart';

class GemmaModelManager {
  GemmaModelManager({ScamModelSpec? spec}) : spec = spec ?? modelCatalog.first;

  ScamModelSpec spec;

  bool get isBundled => spec.assetPath != null;

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await FlutterEdgeAi.initialize(
      inferenceEngines: [
        MediaPipeEngine(),
        const LiteRtLmEngine(),
        const BuiltInAiEngine(),
      ],
    );
    _initialized = true;
  }

  Future<bool> isInstalled() async {
    await ensureInitialized();
    final models = await FlutterEdgeAi.listInstalledModels();
    return models.any((m) => m.contains(spec.fileName));
  }

  Future<bool> ensureInstalled({
    void Function(int progress)? onProgress,
    String? token,
  }) async {
    if (await isInstalled()) return false;
    await install(onProgress: onProgress, token: token);
    return true;
  }

  Future<void> registerFromFile(String path) async {
    await ensureInitialized();
    await FlutterEdgeAi.installModel(
      modelType: spec.modelType,
      fileType: spec.fileType,
    ).fromFile(path).install();
  }

  Future<void> install({
    void Function(int progress)? onProgress,
    String? token,
  }) async {
    await ensureInitialized();
    final builder = FlutterEdgeAi.installModel(
      modelType: spec.modelType,
      fileType: spec.fileType,
    );
    if (spec.isBuiltIn) {
      await BuiltInAi.ensureReady(
        onProgress: (progress) => onProgress?.call(progress),
      );
      await builder.fromBundled(spec.fileName).install();
      return;
    }
    final asset = spec.assetPath;
    if (asset != null) {
      await builder
          .fromAsset(asset)
          .withProgress((progress) => onProgress?.call(progress))
          .install();
      return;
    }
    final trimmed = (token ?? '').trim();
    await builder
        .fromNetwork(
          spec.url,
          foreground: true,
          token: trimmed.isEmpty ? null : trimmed,
        )
        .withProgress((progress) => onProgress?.call(progress))
        .install();
  }

  Future<void> download({
    void Function(int progress)? onProgress,
    String? token,
  }) =>
      install(onProgress: onProgress, token: token);

  Future<void> delete() async {
    await ensureInitialized();
    final models = await FlutterEdgeAi.listInstalledModels();
    for (final model in models) {
      if (model.contains(spec.fileName)) {
        await FlutterEdgeAi.uninstallModel(model);
      }
    }
  }
}
