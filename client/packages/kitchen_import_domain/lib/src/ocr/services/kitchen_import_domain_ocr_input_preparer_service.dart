import '../../import_task/entities/kitchen_import_domain_import_task_entity.dart';
import '../entities/kitchen_import_domain_ocr_quality_entity.dart';

class OcrInputCandidate {
  const OcrInputCandidate({
    required this.localPath,
    required this.source,
    required this.profileIdentifier,
    required this.profileVersion,
    required this.sourceContentRevision,
    required this.pixelWidth,
    required this.pixelHeight,
    this.isDerived = false,
    this.rotationQuarterTurns = 0,
  });

  /// 实际交给平台 OCR 的受控本地文件路径。
  final String localPath;

  /// 候选来自原图、方向归一图还是增强图。
  final OcrInputSource source;

  /// 生成候选所用 profile 的稳定标识。
  final String profileIdentifier;

  /// 生成候选所用 profile 的实现版本。
  final String profileVersion;

  /// 候选对应的媒体内容修订号。
  final int sourceContentRevision;

  /// 方向归一后候选的像素宽度；无法解码时为 0。
  final int pixelWidth;

  /// 方向归一后候选的像素高度；无法解码时为 0。
  final int pixelHeight;

  /// 候选是否为可安全删除的受控派生文件。
  final bool isDerived;

  /// 未能物理归一时仍需由平台应用的顺时针 90° 旋转次数。
  final int rotationQuarterTurns;

  /// 将候选投影为平台 OCR 既有输入，方向已物理归一所以旋转次数固定为零。
  ImportMediaReference asMedia(ImportMediaReference sourceMedia) {
    return ImportMediaReference(
      id: sourceMedia.id,
      localPath: localPath,
      originalLocalPath: sourceMedia.originalLocalPath,
      contentRevision: sourceMedia.contentRevision,
      position: sourceMedia.position,
      rotationQuarterTurns: rotationQuarterTurns,
      ignored: sourceMedia.ignored,
    );
  }

  /// 候选对应的可持久化预处理来源元数据。
  OcrPreprocessMetadata get metadata => OcrPreprocessMetadata(
    source: source,
    profileIdentifier: profileIdentifier,
    profileVersion: profileVersion,
    sourceContentRevision: sourceContentRevision,
  );
}

class OcrInputPreparation {
  const OcrInputPreparation({
    required this.original,
    required this.imageQuality,
    this.enhanced,
  });

  /// 必定存在且可回退的原图或方向归一候选。
  final OcrInputCandidate original;

  /// 质量策略命中时生成的唯一增强候选；否则为空。
  final OcrInputCandidate? enhanced;

  /// 基于方向归一后像素生成的图片质量报告。
  final ImageQualityReport imageQuality;
}

/// OCR 图片解码、方向归一、像素预检和受控派生文件的领域端口。
abstract interface class OcrInputPreparer {
  /// 为一页媒体准备原图候选和至多一个增强候选。
  Future<OcrInputPreparation> prepare(ImportMediaReference media);

  /// OCR 完成或失败后释放无需保留的派生候选。
  Future<void> release(OcrInputPreparation preparation);
}
