import 'package:flutter_gemma/flutter_gemma.dart';

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
}

const List<ScamModelSpec> modelCatalog = [
  ScamModelSpec(
    id: 'qwen2.5-0.5b',
    displayName: 'Qwen2.5 0.5B (download)',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    fileName: 'Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    modelType: ModelType.qwen,
    fileType: ModelFileType.task,
    approxSizeMb: 521,
    contextTokens: 1280,
    note: 'Smallest and fastest. Downloads once, then runs offline.',
  ),
  ScamModelSpec(
    id: 'qwen2.5-1.5b',
    displayName: 'Qwen2.5 1.5B (download)',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    fileName: 'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    modelType: ModelType.qwen,
    fileType: ModelFileType.task,
    approxSizeMb: 1638,
    contextTokens: 1280,
    note: 'Bigger and more accurate than the bundled 0.5B. Downloads once, then runs offline.',
  ),
  ScamModelSpec(
    id: 'deepseek-r1-1.5b',
    displayName: 'DeepSeek-R1 1.5B (reasoning, download)',
    url:
        'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv1280.task',
    fileName:
        'DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv1280.task',
    modelType: ModelType.deepSeek,
    fileType: ModelFileType.task,
    approxSizeMb: 1775,
    thinking: true,
    contextTokens: 1280,
    note: 'Reasoning model: thinks step by step before answering, which can '
        'classify tricky messages better but is slower. Context is capped at '
        '1280 tokens, so long thinking is truncated. Downloads once, then runs '
        'offline.',
  ),
  ScamModelSpec(
    id: 'deepseek-r1-1.5b-long',
    displayName: 'DeepSeek-R1 1.5B, long context (reasoning, download)',
    url:
        'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv4096.litertlm',
    fileName:
        'DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv4096.litertlm',
    modelType: ModelType.deepSeek,
    fileType: ModelFileType.litertlm,
    approxSizeMb: 1749,
    thinking: true,
    contextTokens: 4096,
    note: 'Same reasoning model with a 4096-token context, leaving real room '
        'for thinking. Use this one for the 1.5B. Downloads once, then runs '
        'offline.',
  ),
  ScamModelSpec(
    id: 'qwen3-4b-2507',
    displayName: 'Qwen3 4B Instruct 2507 (download, large)',
    url:
        'https://huggingface.co/litert-community/Qwen3-4B-Instruct-2507/resolve/main/qwen3_4b_instruct_2507_mixed_int4.litertlm',
    fileName: 'qwen3_4b_instruct_2507_mixed_int4.litertlm',
    modelType: ModelType.qwen3,
    fileType: ModelFileType.litertlm,
    approxSizeMb: 2536,
    note: 'Most accurate but large (~2.5 GB, INT4). Needs a flagship phone. Downloads once, then runs offline.',
  ),
  ScamModelSpec(
    id: 'gemma3-1b-it',
    displayName: 'Gemma 3 1B (download, gated)',
    url:
        'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
    fileName: 'gemma3-1b-it-int4.task',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.task,
    approxSizeMb: 554,
    requiresToken: true,
    note: 'Downloaded on demand. The repo is gated: needs a HuggingFace token with access granted.',
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
