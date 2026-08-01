import 'kitchen_import_domain_recipe_draft_entity.dart';
import 'kitchen_import_domain_ocr_document_entity.dart';

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

class ImportMediaReference {
  const ImportMediaReference({
    required this.id,
    required this.localPath,
    required this.position,
    this.rotationQuarterTurns = 0,
    this.ignored = false,
    this.ocrText,
    this.ocrPage,
    this.ocrCompleted = false,
  });

  /// 媒体引用稳定 ID。
  final String id;

  /// 已复制到应用受控目录的本地文件路径。
  final String localPath;

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

  /// 是否已完成本页 OCR，便于中断后只恢复未完成图片。
  final bool ocrCompleted;
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
