/// 图片预检对当前图片的总体判断。
enum ImageQualityLevel { unknown, acceptable, needsAttention }

/// 图片预检发现的离散问题。
enum ImageQualityIssueCode {
  orientationUnknown,
  blurred,
  textMayBeTooSmall,
  lowContrast,
  lowRecipeCoverage,
  excessInterfaceContent,
  metadataLimited,
}

/// 图片问题对应的首选用户动作。
enum ImageQualityRecommendedAction {
  continueRecognition,
  crop,
  rotate,
  replace,
  manualReview,
}

/// OCR 文字本身的可用程度，与菜谱结构是否完整无关。
enum OcrTextQualityLevel { unknown, usable, needsAttention, insufficient }

/// OCR 文字后检发现的离散问题。
enum OcrTextQualityIssueCode {
  garbledText,
  suspectedMissingLines,
  lowConfidenceKeyText,
  excessNoise,
  noEffectiveText,
  metadataLimited,
}

/// 实际交给平台 OCR 的图片来源。
enum OcrInputSource { unknown, original, orientationNormalized, enhanced }

/// 原图与增强图之间的最终选择结果。
enum OcrCandidateSelection { unknown, original, enhanced }

/// 保守纠错建议的原因。
enum OcrCorrectionReason { number, amountUnit, recipeTerm, suspectedGlyphError }

/// 单项纠错建议当前状态。
enum OcrCorrectionSuggestionStatus { pending, applied, rejected }

/// 用户校对层修订的来源。
enum OcrCorrectionRevisionKind {
  suggestion,
  convertToSimplified,
  convertToTraditional,
  manual,
}

class ImageQualityReport {
  const ImageQualityReport({
    this.level = ImageQualityLevel.unknown,
    this.issues = const [],
    this.recommendedAction = ImageQualityRecommendedAction.continueRecognition,
    this.profileVersion = 'unknown',
    this.detail,
  });

  /// 图片预检的总体质量级别。
  final ImageQualityLevel level;

  /// 图片预检命中的离散问题码；未知不等同于没有问题。
  final List<ImageQualityIssueCode> issues;

  /// 根据最重要问题给出的首选用户动作。
  final ImageQualityRecommendedAction recommendedAction;

  /// 生成报告的诊断规则版本；旧任务缺失时为 `unknown`。
  final String profileVersion;

  /// 面向调试和用户解释的简短说明；没有可靠结论时为空。
  final String? detail;
}

class OcrTextQualityEvidence {
  const OcrTextQualityEvidence({
    required this.pageIndex,
    required this.issue,
    required this.message,
    this.lineId,
  });

  /// 风险证据所在的零基页码。
  final int pageIndex;

  /// 风险证据对应的文字质量问题码。
  final OcrTextQualityIssueCode issue;

  /// 风险证据对应的稳定 OCR 行 ID；页面级证据时为空。
  final String? lineId;

  /// 可直接用于界面解释的中文说明。
  final String message;
}

class OcrTextQualityReport {
  const OcrTextQualityReport({
    this.level = OcrTextQualityLevel.unknown,
    this.issues = const [],
    this.evidence = const [],
    this.profileVersion = 'unknown',
  });

  /// OCR 文字的总体可用级别。
  final OcrTextQualityLevel level;

  /// 文档或页面命中的文字质量问题码。
  final List<OcrTextQualityIssueCode> issues;

  /// 可定位到页和文字行的风险证据。
  final List<OcrTextQualityEvidence> evidence;

  /// 生成报告的文字后检规则版本；旧任务缺失时为 `unknown`。
  final String profileVersion;
}

class OcrPlatformMetadata {
  const OcrPlatformMetadata({
    this.engineIdentifier = 'unknown',
    this.engineVersion,
    this.modelBundled,
  });

  /// 平台 OCR 引擎的稳定标识；旧任务缺失时为 `unknown`。
  final String engineIdentifier;

  /// 平台实际返回或应用可确认的引擎版本；无法确认时为空。
  final String? engineVersion;

  /// 模型是否随应用离线打包；无法从平台确认时为空。
  final bool? modelBundled;
}

class OcrPreprocessMetadata {
  const OcrPreprocessMetadata({
    this.source = OcrInputSource.unknown,
    this.profileIdentifier = 'unknown',
    this.profileVersion = 'unknown',
    this.sourceContentRevision = 0,
  });

  /// 本次 OCR 输入来自原图、方向归一图还是增强图。
  final OcrInputSource source;

  /// 预处理 profile 的稳定标识；未执行或旧任务为 `unknown`。
  final String profileIdentifier;

  /// 预处理 profile 的实现版本；未执行或旧任务为 `unknown`。
  final String profileVersion;

  /// 生成该输入时对应的媒体内容修订号。
  final int sourceContentRevision;
}

class OcrCorrectionSuggestion {
  const OcrCorrectionSuggestion({
    required this.id,
    required this.originalText,
    required this.replacementText,
    required this.reason,
    required this.pageIndex,
    this.lineId,
    this.status = OcrCorrectionSuggestionStatus.pending,
  });

  /// 建议稳定 ID，用于跨页面重建和拒绝后保留状态。
  final String id;

  /// 机器 OCR 原文中的待校对片段。
  final String originalText;

  /// 建议用户确认的替换片段。
  final String replacementText;

  /// 生成建议的保守规则原因。
  final OcrCorrectionReason reason;

  /// 建议证据所在的零基页码。
  final int pageIndex;

  /// 建议证据对应的稳定 OCR 行 ID；无法定位时为空。
  final String? lineId;

  /// 建议是待处理、已采用还是已拒绝。
  final OcrCorrectionSuggestionStatus status;
}

class OcrCorrectionRevision {
  const OcrCorrectionRevision({
    required this.id,
    required this.beforeText,
    required this.afterText,
    required this.kind,
    required this.createdAt,
  });

  /// 校对修订稳定 ID。
  final String id;

  /// 修订前的完整用户校对正文。
  final String beforeText;

  /// 修订后的完整用户校对正文。
  final String afterText;

  /// 修订来自建议、用户主动繁简转换还是手动编辑。
  final OcrCorrectionRevisionKind kind;

  /// 修订确认时间。
  final DateTime createdAt;
}

class ImportOcrQualityState {
  const ImportOcrQualityState({
    this.textQuality = const OcrTextQualityReport(),
    this.suggestions = const [],
    this.revisions = const [],
  });

  /// 文档级 OCR 文字质量报告。
  final OcrTextQualityReport textQuality;

  /// 所有纠错建议及其采用或拒绝状态。
  final List<OcrCorrectionSuggestion> suggestions;

  /// 用户校对层的可撤销修订历史。
  final List<OcrCorrectionRevision> revisions;
}
