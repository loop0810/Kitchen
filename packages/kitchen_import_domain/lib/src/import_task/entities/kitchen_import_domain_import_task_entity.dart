import '../../recipe_draft/entities/kitchen_import_domain_recipe_draft_entity.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_document_entity.dart';

enum ImportTaskStatus {
  queued,
  extracting,
  recognizingImages,
  structuring,
  awaitingReview,
  failed,
  saved,
  cancelled,
}

enum ImportInputKind { pastedText, images, sharedText, sharedImages }

enum ImportMediaOcrStatus { pending, processing, succeeded, failed }

class ImportMediaReference {
  const ImportMediaReference({
    required this.id,
    required this.localPath,
    required this.position,
    String? originalLocalPath,
    this.contentRevision = 0,
    this.rotationQuarterTurns = 0,
    this.ignored = false,
    this.ocrText,
    this.ocrPage,
    ImportMediaOcrStatus? ocrStatus,
    bool ocrCompleted = false,
    this.ocrErrorCode,
    this.ocrErrorMessage,
  }) : originalLocalPath = originalLocalPath ?? localPath,
       ocrStatus =
           ocrStatus ??
           (ocrCompleted
               ? ImportMediaOcrStatus.succeeded
               : ImportMediaOcrStatus.pending);

  /// 媒体引用稳定 ID。
  final String id;

  /// 已复制到应用受控目录的本地文件路径。
  final String localPath;

  /// 首次导入时的受控原图路径，裁剪或替换不会改写该引用。
  final String originalLocalPath;

  /// 当前有效图内容的单调递增修订号，用于判断分页 OCR 是否可复用。
  final int contentRevision;

  /// 用户确定的零基处理顺序。
  final int position;

  /// 顺时针旋转的 90° 次数。
  final int rotationQuarterTurns;

  /// 是否跳过本图片的识别和整理。
  final bool ignored;

  /// 本页 OCR 文字；尚未识别或识别失败时为空。
  final String? ocrText;

  /// 本页包含坐标和置信度的 OCR 结构；旧任务或用户手动改写纯文本时为空。
  final OcrPageEntity? ocrPage;

  /// 本页 OCR 的可恢复状态。
  final ImportMediaOcrStatus ocrStatus;

  /// 本页 OCR 的稳定错误分类；非失败状态为空。
  final String? ocrErrorCode;

  /// 本页 OCR 的中文可行动错误说明；非失败状态为空。
  final String? ocrErrorMessage;

  /// 兼容旧调用方的完成标记，权威状态为 [ocrStatus]。
  bool get ocrCompleted => ocrStatus == ImportMediaOcrStatus.succeeded;
}

class ImportTaskEntity {
  const ImportTaskEntity({
    required this.id,
    required this.inputKind,
    required this.status,
    required this.originalText,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
    this.detectedPublicUrl,
    this.ocrText,
    this.correctedOcrText,
    this.supplementalText = '',
    this.processingGeneration = 0,
    this.draft,
    this.errorCode,
    this.errorMessage,
    this.finalRecipeId,
  });

  /// 导入任务稳定 UUID，也是正式菜谱保存的幂等键。
  final String id;

  /// 原始输入类型。
  final ImportInputKind inputKind;

  /// 当前可恢复的业务阶段。
  final ImportTaskStatus status;

  /// 原始文字输入；图片任务或无分享文案时为空字符串。
  final String originalText;

  /// 从原文自动识别的首个公开 HTTPS 地址；没有时为空。
  final Uri? detectedPublicUrl;

  /// 按用户顺序保存的应用内媒体引用。
  final List<ImportMediaReference> media;

  /// 汇总后的 OCR 文字；尚未识别时为空。
  final String? ocrText;

  /// 用户校对后的 OCR 正文；为空时使用机器 OCR 汇总。
  final String? correctedOcrText;

  /// 用户补充的说明文字，与机器 OCR 和校对正文独立保存。
  final String supplementalText;

  /// 媒体内容或顺序变化时递增的处理代次，用于拒绝过期异步回写。
  final int processingGeneration;

  /// 结构化时实际使用的用户文字，校对正文优先于机器 OCR。
  String get effectiveOcrText => correctedOcrText ?? ocrText ?? '';

  /// 最新版本化结构草稿；尚未整理时为空。
  final RecipeDraftEntity? draft;

  /// 稳定错误分类；非失败状态为空。
  final String? errorCode;

  /// 面向用户的错误说明；非失败状态为空。
  final String? errorMessage;

  /// 保存成功后的正式菜谱 ID。
  final String? finalRecipeId;

  /// 任务首次持久化时间。
  final DateTime createdAt;

  /// 任务状态或内容最近更新时间。
  final DateTime updatedAt;
}
