import 'kitchen_import_domain_import_task_entity.dart';
import 'kitchen_import_domain_recipe_draft_entity.dart';

abstract interface class ImportTaskRepository {
  Stream<List<ImportTaskEntity>> watchTasks();

  Future<ImportTaskEntity?> getTask(String taskId);

  Future<String> createTextTask(String originalText);

  Future<String> createImageTask(List<String> controlledLocalPaths);

  Future<String> createSharedTask({
    required String originalText,
    required List<String> controlledLocalPaths,
  });

  Future<void> updateStatus(String taskId, ImportTaskStatus status);

  Future<void> saveOcrText(String taskId, String text);

  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required String text,
  });

  Future<void> saveDraft(String taskId, RecipeDraftEntity draft);

  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
  });

  Future<void> retry(String taskId);

  Future<void> cancel(String taskId);

  Future<void> delete(String taskId);

  Future<void> markSaved({required String taskId, required String recipeId});
}
