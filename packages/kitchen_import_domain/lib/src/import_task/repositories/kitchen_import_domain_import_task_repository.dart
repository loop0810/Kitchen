import '../entities/kitchen_import_domain_import_task_entity.dart';
import '../../ocr/entities/kitchen_import_domain_ocr_document_entity.dart';
import '../../recipe_draft/entities/kitchen_import_domain_recipe_draft_entity.dart';

abstract interface class ImportTaskRepository {
  Stream<List<ImportTaskEntity>> watchTasks();

  Future<ImportTaskEntity?> getTask(String taskId);

  Future<String> createTextTask(String originalText);

  Future<String> createImageTask(List<String> controlledLocalPaths);

  Future<String> createSharedTask({
    required String originalText,
    required List<String> controlledLocalPaths,
  });

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

  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required OcrPageEntity page,
    int? expectedGeneration,
  });

  Future<void> markMediaOcrProcessing({
    required String taskId,
    required String mediaId,
    int? expectedGeneration,
  });

  Future<void> saveMediaOcrFailure({
    required String taskId,
    required String mediaId,
    required String code,
    required String message,
    int? expectedGeneration,
  });

  Future<void> saveDraft(
    String taskId,
    RecipeDraftEntity draft, {
    int? expectedGeneration,
  });

  Future<void> saveReviewDraft(String taskId, RecipeDraftEntity draft);

  Future<void> saveCorrectedOcrText(String taskId, String text);

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

  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
    int? expectedGeneration,
  });

  Future<void> retry(String taskId);

  Future<void> cancel(String taskId);

  Future<void> delete(String taskId);

  Future<void> markSaved({required String taskId, required String recipeId});
}
