import 'package:drift/drift.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:uuid/uuid.dart';

import 'kitchen_import_data_app_database.dart';
import 'kitchen_import_data_import_task_mapper.dart';

class ImportTaskRepositoryImpl implements ImportTaskRepository {
  ImportTaskRepositoryImpl(this._database);

  final ImportAppDatabase _database;
  final _uuid = const Uuid();

  static final _publicUrl = RegExp(
    r'https?://[^\s<>"，。]+',
    caseSensitive: false,
  );

  @override
  Stream<List<ImportTaskEntity>> watchTasks() {
    return _database.watchImportTasks().map(
      (rows) => rows.map(ImportTaskMapper.toDomain).toList(growable: false),
    );
  }

  @override
  Future<ImportTaskEntity?> getTask(String taskId) async {
    final row = await _database.getImportTask(taskId);
    return row == null ? null : ImportTaskMapper.toDomain(row);
  }

  @override
  Future<String> createTextTask(String originalText) async {
    final normalized = originalText.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(originalText, 'originalText', '原始文字不能为空');
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    final detectedPublicUrl = _detectedPublicUrl(normalized);
    await _database
        .into(_database.importTasks)
        .insert(
          ImportTasksCompanion.insert(
            id: id,
            inputKind: ImportInputKind.pastedText.name,
            status: ImportTaskStatus.queued.name,
            originalText: Value(normalized),
            detectedPublicUrl: Value(detectedPublicUrl?.toString()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<String> createImageTask(List<String> controlledLocalPaths) async {
    if (controlledLocalPaths.isEmpty) {
      throw ArgumentError.value(
        controlledLocalPaths,
        'controlledLocalPaths',
        '至少需要一张图片',
      );
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    final media = controlledLocalPaths.indexed
        .map(
          (item) => ImportMediaReference(
            id: _uuid.v4(),
            localPath: item.$2,
            position: item.$1,
          ),
        )
        .toList(growable: false);
    await _database
        .into(_database.importTasks)
        .insert(
          ImportTasksCompanion.insert(
            id: id,
            inputKind: ImportInputKind.images.name,
            status: ImportTaskStatus.queued.name,
            mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<String> createSharedTask({
    required String originalText,
    required List<String> controlledLocalPaths,
  }) async {
    final normalized = originalText.trim();
    if (normalized.isEmpty && controlledLocalPaths.isEmpty) {
      throw ArgumentError('系统分享必须包含文字、链接或图片。');
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    final media = controlledLocalPaths.indexed
        .map(
          (item) => ImportMediaReference(
            id: _uuid.v4(),
            localPath: item.$2,
            position: item.$1,
          ),
        )
        .toList(growable: false);
    await _database
        .into(_database.importTasks)
        .insert(
          ImportTasksCompanion.insert(
            id: id,
            inputKind: media.isEmpty
                ? ImportInputKind.sharedText.name
                : ImportInputKind.sharedImages.name,
            status: ImportTaskStatus.queued.name,
            originalText: Value(normalized),
            detectedPublicUrl: Value(
              _detectedPublicUrl(normalized)?.toString(),
            ),
            mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Uri? _detectedPublicUrl(String text) {
    final value = _publicUrl.firstMatch(text)?.group(0);
    final parsed = value == null ? null : Uri.tryParse(value);
    if (parsed == null) return null;
    // 只进行本地 scheme 升级，绝不发送明文 HTTP 请求；目标不支持 HTTPS 时由
    // 安全提取器按“不可访问”降级并保留原始分享文案。
    return parsed.scheme.toLowerCase() == 'http'
        ? parsed.replace(scheme: 'https')
        : parsed;
  }

  @override
  Future<void> updateStatus(String taskId, ImportTaskStatus status) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(status.name),
        errorCode: const Value(null),
        errorMessage: const Value(null),
      ),
    );
  }

  @override
  Future<void> saveOcrText(String taskId, String text) {
    return _write(taskId, ImportTasksCompanion(ocrText: Value(text)));
  }

  @override
  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required String text,
  }) async {
    final task = await getTask(taskId);
    if (task == null) throw StateError('Import task $taskId does not exist.');
    final media = task.media
        .map(
          (item) => item.id == mediaId
              ? ImportMediaReference(
                  id: item.id,
                  localPath: item.localPath,
                  position: item.position,
                  rotationQuarterTurns: item.rotationQuarterTurns,
                  ignored: item.ignored,
                  ocrText: text,
                  ocrCompleted: true,
                )
              : item,
        )
        .toList(growable: false);
    await _write(
      taskId,
      ImportTasksCompanion(
        mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
      ),
    );
  }

  @override
  Future<void> saveDraft(String taskId, RecipeDraftEntity draft) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(ImportTaskStatus.awaitingReview.name),
        draftJson: Value(ImportTaskMapper.encodeDraft(draft)),
        errorCode: const Value(null),
        errorMessage: const Value(null),
      ),
    );
  }

  @override
  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
  }) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(ImportTaskStatus.failed.name),
        errorCode: Value(code),
        errorMessage: Value(message),
      ),
    );
  }

  @override
  Future<void> retry(String taskId) {
    return updateStatus(taskId, ImportTaskStatus.queued);
  }

  @override
  Future<void> cancel(String taskId) {
    return updateStatus(taskId, ImportTaskStatus.cancelled);
  }

  @override
  Future<void> delete(String taskId) => _database.deleteImportTask(taskId);

  @override
  Future<void> markSaved({required String taskId, required String recipeId}) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(ImportTaskStatus.saved.name),
        finalRecipeId: Value(recipeId),
      ),
    );
  }

  Future<void> _write(String taskId, ImportTasksCompanion changes) async {
    final affected =
        await (_database.update(_database.importTasks)
              ..where((row) => row.id.equals(taskId)))
            .write(changes.copyWith(updatedAt: Value(DateTime.now())));
    if (affected == 0) throw StateError('Import task $taskId does not exist.');
  }
}
