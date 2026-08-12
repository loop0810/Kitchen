import '../entities/kitchen_import_domain_import_task_entity.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_document_entity.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_quality_entity.dart';
import '../../recipe_draft/entities/kitchen_import_domain_recipe_draft_entity.dart';

/// 导入领域与持久化实现之间的端口。
///
/// 流水线通过这个接口把每个阶段独立落盘，而不是在内存中从头跑到尾。
/// Data 层实现还负责用 `expectedGeneration` 拒绝过期异步结果。
abstract interface class ImportTaskRepository {
  /// 监听全部任务；导入箱和任务详情由同一个持久化流驱动。
  Stream<List<ImportTaskEntity>> watchTasks();

  /// 读取一次任务快照，供状态机判断取消和处理代次。
  Future<ImportTaskEntity?> getTask(String taskId);

  /// 先持久化粘贴文字，再返回可交给流水线处理的任务 ID。
  Future<String> createTextTask(String originalText);

  /// 用已经复制到应用受控目录的图片创建任务。
  Future<String> createImageTask(List<String> controlledLocalPaths);

  /// 将系统分享的文字和媒体统一接管为一个可恢复任务。
  Future<String> createSharedTask({
    required String originalText,
    required List<String> controlledLocalPaths,
    String? sourceShareId,
  });

  /// 按外部系统分享 ID 查找已经创建的导入任务，用于重复接管幂等处理。
  Future<String?> findSharedTask(String sourceShareId);

  /// 推进业务状态；指定代次时，旧处理批次不得改变新任务状态。
  Future<void> updateStatus(
    String taskId,
    ImportTaskStatus status, {
    int? expectedGeneration,
  });

  Future<void> saveOcrText(
    String taskId,
    String text, {
    int? expectedGeneration,
  });

  /// 保存单页带坐标 OCR，使成功页面可在重试时直接复用。
  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required OcrPageEntity page,
    int? expectedGeneration,
  });

  /// 保存图片预检报告和最终候选，仍以 generation 拒绝过期结果。
  Future<void> saveMediaOcrQuality({
    required String taskId,
    required String mediaId,
    required ImageQualityReport imageQuality,
    required OcrCandidateSelection selectedCandidate,
    int? expectedGeneration,
  });

  /// 原子保存文档级文字质量、纠错建议和修订历史。
  Future<void> saveOcrQuality(
    String taskId,
    ImportOcrQualityState quality, {
    int? expectedGeneration,
  });

  /// 采用单项建议并把差异写入可撤销的用户校对层。
  Future<void> applyOcrCorrectionSuggestion(String taskId, String suggestionId);

  /// 拒绝单项建议并持久保留拒绝状态。
  Future<void> rejectOcrCorrectionSuggestion(
    String taskId,
    String suggestionId,
  );

  /// 保存用户确认的整段转换或手动编辑，并记录可撤销修订。
  Future<void> saveOcrCorrectionRevision({
    required String taskId,
    required String text,
    required OcrCorrectionRevisionKind kind,
  });

  /// 撤销最近一次校对修订；没有历史时不改变正文。
  Future<void> undoLastOcrCorrection(String taskId);

  /// 在调用平台 OCR 前标记单页状态，便于中断后识别未完成页面。
  Future<void> markMediaOcrProcessing({
    required String taskId,
    required String mediaId,
    int? expectedGeneration,
  });

  /// 单独记录失败页面，不清除同一任务中其他成功页面。
  Future<void> saveMediaOcrFailure({
    required String taskId,
    required String mediaId,
    required String code,
    required String message,
    int? expectedGeneration,
  });

  /// 保存自动结构化结果，并把任务推进到等待用户审核。
  Future<void> saveDraft(
    String taskId,
    RecipeDraftEntity draft, {
    int? expectedGeneration,
  });

  /// 自动保存审核页当前值；写入后用户退出页面仍可继续。
  Future<void> saveReviewDraft(String taskId, RecipeDraftEntity draft);

  /// 保存用户校对层，机器 OCR 原文仍保持不变。
  Future<void> saveCorrectedOcrText(String taskId, String text);

  /// 保存独立补充说明，避免与原文或 OCR 结果混为同一个事实源。
  Future<void> saveSupplementalText(String taskId, String text);

  Future<void> appendMedia(String taskId, List<String> controlledLocalPaths);

  Future<void> replaceMedia({
    required String taskId,
    required String mediaId,
    required String controlledLocalPath,
  });

  Future<void> submitCroppedMedia({
    required String taskId,
    required String mediaId,
    required String controlledLocalPath,
  });

  Future<void> reorderMedia(String taskId, List<String> orderedMediaIds);

  Future<void> rotateMedia(String taskId, String mediaId);

  Future<void> setMediaIgnored(String taskId, String mediaId, bool ignored);

  Future<void> retryMediaOcr(String taskId, String mediaId);

  /// 记录可恢复错误；原始材料和既有中间结果继续保留。
  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
    int? expectedGeneration,
  });

  Future<void> retry(String taskId);

  Future<void> cancel(String taskId);

  Future<void> delete(String taskId);

  /// 删除全部导入任务并清理其受控媒体。
  Future<void> deleteAll();

  /// 记录正式菜谱关联，重复进入确认页时可跳转到同一菜谱。
  Future<void> markSaved({required String taskId, required String recipeId});
}
