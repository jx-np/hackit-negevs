import 'package:flutter_gemma/flutter_gemma.dart';

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
    this.note = '',
    this.assetPath,
  });

  final String id;
  final String displayName;
  final String url;
  final String fileName;
  final ModelType modelType;
  final ModelFileType fileType;
  final int approxSizeMb;
  final bool requiresToken;
  final String note;
  final String? assetPath;
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
    note: 'Bigger and more accurate than the bundled 0.5B. Downloads once, then runs offline.',
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

ScamModelSpec modelById(String id) => modelCatalog.firstWhere(
      (spec) => spec.id == id,
      orElse: () => modelCatalog.first,
    );
