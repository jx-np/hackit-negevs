import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_builtin_ai/flutter_edge_ai_builtin_ai.dart';

const String kCustomModelId = 'custom-local';

class ScamModelSpec {
  const ScamModelSpec({
    required this.id,
    required this.displayName,
    required this.url,
    required this.fileName,
    required this.modelType,
    required this.fileType,
    required this.approxSizeMb,
    this.requiresToken = false,
    this.thinking = false,
    this.contextTokens = 1024,
    this.note = '',
    this.assetPath,
    this.filePath,
  });

  final String id;
  final String displayName;
  final String url;
  final String fileName;
  final ModelType modelType;
  final ModelFileType fileType;
  final int approxSizeMb;
  final bool requiresToken;

  /// True for reasoning models that emit a ` thinking...<｜end▁of▁thinking｜>` block before
  /// their answer. They get a larger output budget and their thinking is
  /// stripped before the JSON verdict is parsed.
  final bool thinking;

  /// Total context window (input + output) requested when the model is loaded.
  /// MediaPipe `.task` files are capped by the KV cache baked in at conversion
  /// (the `ekv` in the filename); `.litertlm` files honour the value up to
  /// their own maximum.
  final int contextTokens;
  final String note;
  final String? assetPath;

  /// Absolute path of a model file the user picked on this device. Set only
  /// for [kCustomModelId]; when present the file is used in place instead of
  /// being downloaded into the ScamShield folder.
  final String? filePath;

  bool get isBuiltIn => fileType == ModelFileType.builtIn;
}

final List<ScamModelSpec> modelCatalog = [
  ScamModelSpec(
    id: 'gemma-4-e2b',
    displayName: 'Big Model',
    url: 'https://img.jhh.moe/raw/gemma-4-E2B-it.litertlm',
    fileName: 'gemma-4-E2B-it.litertlm',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.litertlm,
    approxSizeMb: 3100,
    contextTokens: 4096,
    note: 'Runs entirely on your phone. Downloads once, then works offline.',
  ),
  ScamModelSpec(
    id: 'qwen3-1-7B',
    displayName: 'Small Model',
    url: 'https://img.jhh.moe/raw/Qwen3-1.7B_dynamic_wi4b32_afp32.litertlm',
    fileName: 'Qwen3-1.7B_dynamic_wi4b32_afp32.litertlm',
    modelType: ModelType.qwen3,
    fileType: ModelFileType.litertlm,
    approxSizeMb: 1000,
    contextTokens: 4096,
    note: 'Runs entirely on your phone. Downloads once, then works offline.',
  ),
];

ScamModelSpec? _customModel;

/// The model the user picked from this device's storage, or null when none
/// has been picked. It is held here so every call site that already resolves
/// specs through [modelById] or [allModels] sees it without a signature change.
ScamModelSpec? get customModelSpec => _customModel;

set customModelSpec(ScamModelSpec? value) => _customModel = value;

void clearCustomModelSpec() => _customModel = null;

List<ScamModelSpec> get allModels => _customModel == null
    ? modelCatalog
    : [...modelCatalog, _customModel!];

ScamModelSpec modelById(String id) => allModels.firstWhere(
      (spec) => spec.id == id,
      orElse: () => modelCatalog.first,
    );

/// Builds the catalog entry for a model file sitting at [path]. The file type
/// comes from the extension: `.litertlm` must be declared explicitly because
/// `installModel` otherwise assumes `.task` and routes the file to MediaPipe.
///
/// The model type has to come from the file name as well — MediaPipe derives
/// the chat template from it for `.task` files, and MiniCPM/LLaMA-style models
/// are `LlamaForCausalLM` under the hood, so that is the safe default.
ScamModelSpec buildCustomModelSpec({
  required String path,
  required String name,
  required int contextTokens,
  required bool thinking,
  required int sizeMb,
}) {
  final fileName = path.split(RegExp(r'[\\/]')).last;
  final lower = fileName.toLowerCase();
  final litertlm = lower.endsWith('.litertlm');
  return ScamModelSpec(
    id: kCustomModelId,
    displayName: name,
    url: '',
    fileName: fileName,
    modelType: _modelTypeFor(lower),
    fileType: litertlm ? ModelFileType.litertlm : ModelFileType.task,
    approxSizeMb: sizeMb,
    contextTokens: contextTokens,
    thinking: thinking,
    filePath: path,
    note: 'Loaded from a file on this device (testing).',
  );
}

ModelType _modelTypeFor(String fileName) {
  if (fileName.contains('deepseek')) return ModelType.deepSeek;
  if (fileName.contains('qwen3')) return ModelType.qwen3;
  if (fileName.contains('qwen')) return ModelType.qwen;
  if (fileName.contains('gemma')) return ModelType.gemmaIt;
  if (RegExp(r'(^|[^a-z])phi[ _-]?\d').hasMatch(fileName)) {
    return ModelType.phi;
  }
  return ModelType.llama;
}
