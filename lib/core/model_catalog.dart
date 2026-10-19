import 'package:flutter_edge_ai/flutter_edge_ai.dart';

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

  /// True for `.gguf` files. They are loaded by llamadart straight from the
  /// picked path (see `lib/services/gguf_llm_evaluator.dart`), so they are
  /// never registered with flutter_edge_ai or copied into the model store.
  bool get isGguf => fileType == ModelFileType.gguf;
}

/// The id of the built-in Android system model (Gemini Nano via AICore).
const String kBuiltInModelId = 'aicore-system';

/// The model selected by default on a fresh install. The built-in AICore entry
/// leads the catalog for prominence in the UI, but it is unavailable on most
/// devices, so the out-of-the-box default must point at a model that can always
/// be downloaded. This is also the fallback [modelById] returns for unknown ids.
const String kDefaultModelId = 'gemma-4-e2b';

final List<ScamModelSpec> modelCatalog = [
  ScamModelSpec(
    id: kBuiltInModelId,
    displayName: 'System AI (AICore)',
    url: '',
    // Must equal BuiltInAiModels.geminiNano.name so the built-in install path
    // in GemmaModelManager can resolve it via builder.fromBundled(...).
    fileName: 'gemini-nano',
    modelType: ModelType.general,
    fileType: ModelFileType.builtIn,
    approxSizeMb: 0,
    contextTokens: 4096,
    note:
        'Uses the AI built into your Android system. No download, nothing to '
        'store. Only available on supported devices.',
  ),
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

/// The catalog entry used as the safe default: the first non-built-in model,
/// falling back to the first catalog entry if somehow none exists.
ScamModelSpec get defaultModel => modelCatalog.firstWhere(
      (spec) => spec.id == kDefaultModelId,
      orElse: () => modelCatalog.firstWhere(
        (spec) => !spec.isBuiltIn,
        orElse: () => modelCatalog.first,
      ),
    );

ScamModelSpec modelById(String id) => allModels.firstWhere(
      (spec) => spec.id == id,
      orElse: () => defaultModel,
    );

/// Builds the catalog entry for a model file sitting at [path]. The file type
/// comes from the extension: `.litertlm` must be declared explicitly because
/// `installModel` otherwise assumes `.task` and routes the file to MediaPipe,
/// and `.gguf` must be declared so the file is routed to llamadart instead.
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
  // Anything else would be handed to MediaPipe, which cannot load a GGUF.
  final gguf = lower.endsWith('.gguf');
  return ScamModelSpec(
    id: kCustomModelId,
    displayName: name,
    url: '',
    fileName: fileName,
    modelType: _modelTypeFor(lower),
    fileType: gguf
        ? ModelFileType.gguf
        : (litertlm ? ModelFileType.litertlm : ModelFileType.task),
    approxSizeMb: sizeMb,
    contextTokens: contextTokens,
    thinking: thinking,
    filePath: path,
    note: 'Loaded from a file on this device (testing).',
  );
}

ModelType _modelTypeFor(String fileName) {
  if (fileName.contains('deepseek')) return ModelType.deepSeek;
  // Must be checked before the `qwen3` branch: "qwen3.5" also contains "qwen3".
  // Cosmetic for the llama.cpp path (it reads the template from the GGUF), but
  // it keeps the settings UI honest about what the file is.
  if (fileName.contains('qwen3.5') || fileName.contains('qwen-3.5')) {
    return ModelType.qwen35;
  }
  if (fileName.contains('qwen3')) return ModelType.qwen3;
  if (fileName.contains('qwen')) return ModelType.qwen;
  if (fileName.contains('gemma')) return ModelType.gemmaIt;
  if (RegExp(r'(^|[^a-z])phi[ _-]?\d').hasMatch(fileName)) {
    return ModelType.phi;
  }
  return ModelType.llama;
}
