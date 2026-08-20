import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../database/kitchen_import_data_app_database.dart';
import '../mappers/kitchen_import_data_import_task_mapper.dart';

class ImportTaskRepositoryImpl implements ImportTaskRepository {
  ImportTaskRepositoryImpl(
    this._database, {
    Future<Directory> Function()? mediaDirectoryProvider,
  }) : _mediaDirectoryProvider =
           mediaDirectoryProvider ?? _defaultMediaDirectory;

  final ImportAppDatabase _database;
  final Future<Directory> Function() _mediaDirectoryProvider;
  final _uuid = const Uuid();

  static final _publicUrl = RegExp(
    r'https?://[^\s<>"，。]+',
    caseSensitive: false,
  );

  @override
  Stream<List<ImportTaskEntity>> watchTasks() {
    // UI 订阅的是领域实体流，不接触 Drift Row；数据库变化会自动推动导入箱刷新。
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
    // 这里只保存应用受控目录中的路径。系统相册返回的临时引用必须先复制到
    // 受控目录，否则应用重启或系统清理临时文件后，任务会变成“有记录但无图片”。
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
    String? sourceShareId,
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
            sourceShareId: Value(sourceShareId),
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

  @override
  Future<String?> findSharedTask(String sourceShareId) async {
    final row =
        await (_database.select(_database.importTasks)
              ..where((task) => task.sourceShareId.equals(sourceShareId)))
            .getSingleOrNull();
    return row?.id;
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
  Future<void> updateStatus(
    String taskId,
    ImportTaskStatus status, {
    int? expectedGeneration,
  }) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(status.name),
        errorCode: const Value(null),
        errorMessage: const Value(null),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> saveOcrText(
    String taskId,
    String text, {
    int? expectedGeneration,
  }) {
    return _write(
      taskId,
      ImportTasksCompanion(ocrText: Value(text)),
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required OcrPageEntity page,
    int? expectedGeneration,
  }) async {
    final task = await getTask(taskId);
    if (task == null) throw StateError('Import task $taskId does not exist.');
    if (expectedGeneration != null &&
        task.processingGeneration != expectedGeneration) {
      // 旧处理批次的结果静默丢弃：这是并发 OCR 的关键防线，避免旧图片结果覆盖新图片。
      return;
    }
    final media = task.media
        .map(
          (item) => item.id == mediaId
              ? ImportMediaReference(
                  id: item.id,
                  localPath: item.localPath,
                  originalLocalPath: item.originalLocalPath,
                  contentRevision: item.contentRevision,
                  position: item.position,
                  rotationQuarterTurns: item.rotationQuarterTurns,
                  ignored: item.ignored,
                  ocrText: page.plainText,
                  ocrPage: page,
                  ocrStatus: ImportMediaOcrStatus.succeeded,
                )
              : item,
        )
        .toList(growable: false);
    await _write(
      taskId,
      ImportTasksCompanion(
        mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> markMediaOcrProcessing({
    required String taskId,
    required String mediaId,
    int? expectedGeneration,
  }) async {
    final task = await getTask(taskId);
    if (task == null) throw StateError('Import task $taskId does not exist.');
    if (expectedGeneration != null &&
        task.processingGeneration != expectedGeneration) {
      return;
    }
    final media = task.media
        .map(
          (item) => item.id == mediaId
              ? _copyMedia(item, ocrStatus: ImportMediaOcrStatus.processing)
              : item,
        )
        .toList(growable: false);
    await _write(
      taskId,
      ImportTasksCompanion(
        mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> saveMediaOcrFailure({
    required String taskId,
    required String mediaId,
    required String code,
    required String message,
    int? expectedGeneration,
  }) async {
    final task = await getTask(taskId);
    if (task == null) throw StateError('Import task $taskId does not exist.');
    if (expectedGeneration != null &&
        task.processingGeneration != expectedGeneration) {
      return;
    }
    final media = task.media
        .map(
          (item) => item.id == mediaId
              ? _copyMedia(
                  item,
                  ocrStatus: ImportMediaOcrStatus.failed,
                  ocrErrorCode: code,
                  ocrErrorMessage: message,
                )
              : item,
        )
        .toList(growable: false);
    await _write(
      taskId,
      ImportTasksCompanion(
        mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> saveDraft(
    String taskId,
    RecipeDraftEntity draft, {
    int? expectedGeneration,
  }) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(ImportTaskStatus.awaitingReview.name),
        draftJson: Value(ImportTaskMapper.encodeDraft(draft)),
        errorCode: const Value(null),
        errorMessage: const Value(null),
      ),
      expectedGeneration: expectedGeneration,
    );
  }

  @override
  Future<void> saveReviewDraft(String taskId, RecipeDraftEntity draft) {
    return _writeAndAdvanceGeneration(
      taskId,
      ImportTasksCompanion(
        draftJson: Value(ImportTaskMapper.encodeDraft(draft)),
      ),
    );
  }

  @override
  Future<void> saveCorrectedOcrText(String taskId, String text) {
    return _writeAndAdvanceGeneration(
      taskId,
      ImportTasksCompanion(
        correctedOcrText: Value(text.trim()),
        status: Value(ImportTaskStatus.queued.name),
      ),
    );
  }

  @override
  Future<void> saveSupplementalText(String taskId, String text) {
    return _writeAndAdvanceGeneration(
      taskId,
      ImportTasksCompanion(
        supplementalText: Value(text.trim()),
        status: Value(ImportTaskStatus.queued.name),
      ),
    );
  }

  @override
  Future<void> appendMedia(
    String taskId,
    List<String> controlledLocalPaths,
  ) async {
    if (controlledLocalPaths.isEmpty) return;
    for (final path in controlledLocalPaths) {
      await _assertControlledMedia(path);
    }
    await _mutateMedia(taskId, (task) {
      final next = [...task.media];
      for (final path in controlledLocalPaths) {
        next.add(
          ImportMediaReference(
            id: _uuid.v4(),
            localPath: path,
            position: next.length,
          ),
        );
      }
      return next;
    });
  }

  @override
  Future<void> replaceMedia({
    required String taskId,
    required String mediaId,
    required String controlledLocalPath,
  }) {
    return _replaceMedia(
      taskId: taskId,
      mediaId: mediaId,
      controlledLocalPath: controlledLocalPath,
      preserveOriginal: false,
    );
  }

  @override
  Future<void> submitCroppedMedia({
    required String taskId,
    required String mediaId,
    required String controlledLocalPath,
  }) {
    return _replaceMedia(
      taskId: taskId,
      mediaId: mediaId,
      controlledLocalPath: controlledLocalPath,
      preserveOriginal: true,
    );
  }

  Future<void> _replaceMedia({
    required String taskId,
    required String mediaId,
    required String controlledLocalPath,
    required bool preserveOriginal,
  }) async {
    await _assertControlledMedia(controlledLocalPath);
    String? stalePath;
    await _mutateMedia(taskId, (task) {
      var found = false;
      final next = task.media
          .map((item) {
            if (item.id != mediaId) return item;
            found = true;
            stalePath = item.localPath;
            return ImportMediaReference(
              id: item.id,
              localPath: controlledLocalPath,
              originalLocalPath: preserveOriginal
                  ? item.originalLocalPath
                  : controlledLocalPath,
              contentRevision: item.contentRevision + 1,
              position: item.position,
              rotationQuarterTurns: 0,
              ignored: item.ignored,
            );
          })
          .toList(growable: false);
      if (!found) throw StateError('Import media $mediaId does not exist.');
      return next;
    });
    if (stalePath != null && stalePath != controlledLocalPath) {
      await _deleteMediaIfUnreferenced(stalePath!);
    }
  }

  @override
  Future<void> reorderMedia(String taskId, List<String> orderedMediaIds) {
    return _mutateMedia(taskId, (task) {
      if (orderedMediaIds.length != task.media.length ||
          orderedMediaIds.toSet().length != task.media.length) {
        throw ArgumentError('图片顺序必须完整包含任务中的全部媒体。');
      }
      final byId = {for (final item in task.media) item.id: item};
      return orderedMediaIds.indexed
          .map((entry) {
            final item = byId[entry.$2];
            if (item == null) throw ArgumentError('图片顺序包含未知媒体。');
            return _copyMedia(item, position: entry.$1);
          })
          .toList(growable: false);
    });
  }

  @override
  Future<void> rotateMedia(String taskId, String mediaId) {
    return _mutateMedia(taskId, (task) {
      return task.media
          .map(
            (item) => item.id == mediaId
                ? ImportMediaReference(
                    id: item.id,
                    localPath: item.localPath,
                    originalLocalPath: item.originalLocalPath,
                    contentRevision: item.contentRevision + 1,
                    position: item.position,
                    rotationQuarterTurns: (item.rotationQuarterTurns + 1) % 4,
                    ignored: item.ignored,
                  )
                : item,
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> setMediaIgnored(String taskId, String mediaId, bool ignored) {
    return _mutateMedia(
      taskId,
      (task) => task.media
          .map(
            (item) =>
                item.id == mediaId ? _copyMedia(item, ignored: ignored) : item,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> retryMediaOcr(String taskId, String mediaId) {
    return _mutateMedia(
      taskId,
      (task) => task.media
          .map(
            (item) => item.id == mediaId
                ? ImportMediaReference(
                    id: item.id,
                    localPath: item.localPath,
                    originalLocalPath: item.originalLocalPath,
                    contentRevision: item.contentRevision,
                    position: item.position,
                    rotationQuarterTurns: item.rotationQuarterTurns,
                    ignored: item.ignored,
                  )
                : item,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
    int? expectedGeneration,
  }) {
    return _write(
      taskId,
      ImportTasksCompanion(
        status: Value(ImportTaskStatus.failed.name),
        errorCode: Value(code),
        errorMessage: Value(message),
      ),
      expectedGeneration: expectedGeneration,
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
  Future<void> delete(String taskId) async {
    final task = await getTask(taskId);
    // 数据库先成为权威状态；文件清理失败时保留给启动期孤立清理重试。
    await _database.deleteImportTask(taskId);
    if (task == null) return;
    final paths = task.media
        .expand((media) => [media.originalLocalPath, media.localPath])
        .toSet();
    for (final path in paths) {
      await _deleteControlledMedia(path);
    }
  }

  @override
  Future<void> deleteAll() async {
    final tasks = await _database.select(_database.importTasks).get();
    for (final row in tasks) {
      await delete(row.id);
    }
  }

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

  Future<void> _write(
    String taskId,
    ImportTasksCompanion changes, {
    int? expectedGeneration,
  }) async {
    final query = _database.update(_database.importTasks)
      ..where((row) => row.id.equals(taskId));
    if (expectedGeneration != null) {
      query.where((row) => row.processingGeneration.equals(expectedGeneration));
    }
    final affected = await query.write(
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
    if (affected != 0) return;
    if (await _database.getImportTask(taskId) == null) {
      throw StateError('Import task $taskId does not exist.');
    }
    // 任务仍存在却无行被更新，说明旧 generation 已过期；
    // 静默丢弃该异步结果，不覆盖用户的新图片或新顺序。
  }

  Future<void> _writeAndAdvanceGeneration(
    String taskId,
    ImportTasksCompanion changes,
  ) async {
    await _database.transaction(() async {
      final row = await _database.getImportTask(taskId);
      if (row == null) throw StateError('Import task $taskId does not exist.');
      await _write(
        taskId,
        changes.copyWith(
          processingGeneration: Value(row.processingGeneration + 1),
        ),
        expectedGeneration: row.processingGeneration,
      );
    });
  }

  Future<void> _mutateMedia(
    String taskId,
    List<ImportMediaReference> Function(ImportTaskEntity task) mutate,
  ) async {
    await _database.transaction(() async {
      final row = await _database.getImportTask(taskId);
      if (row == null) throw StateError('Import task $taskId does not exist.');
      final task = ImportTaskMapper.toDomain(row);
      final media = mutate(task);
      await _write(
        taskId,
        ImportTasksCompanion(
          mediaJson: Value(ImportTaskMapper.encodeMedia(media)),
          ocrText: const Value(null),
          status: Value(ImportTaskStatus.queued.name),
          errorCode: const Value(null),
          errorMessage: const Value(null),
          processingGeneration: Value(task.processingGeneration + 1),
        ),
        expectedGeneration: task.processingGeneration,
      );
    });
  }

  /// 清理由任务数据库不再引用的受控媒体文件。
  Future<void> cleanupOrphanedMedia() async {
    final root = await _mediaDirectoryProvider();
    if (!await root.exists()) return;
    final referenced = (await _database.select(_database.importTasks).get())
        .map(ImportTaskMapper.toDomain)
        .expand((task) => task.media)
        .expand((media) => [media.originalLocalPath, media.localPath])
        .map(p.normalize)
        .toSet();
    final staleBefore = DateTime.now().subtract(const Duration(days: 1));
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && !referenced.contains(p.normalize(entity.path))) {
        // 系统分享会先复制文件再创建任务。宽限期避免启动清理与这段短暂的
        // “尚未入库”窗口竞态，真正孤立文件会在后续启动被回收。
        if ((await entity.stat()).modified.isAfter(staleBefore)) continue;
        await _deleteControlledMedia(entity.path);
      }
    }
  }

  Future<void> _deleteMediaIfUnreferenced(String candidatePath) async {
    final referenced = (await _database.select(_database.importTasks).get())
        .map(ImportTaskMapper.toDomain)
        .expand((task) => task.media)
        .expand((media) => [media.originalLocalPath, media.localPath])
        .map(p.normalize)
        .contains(p.normalize(candidatePath));
    if (!referenced) await _deleteControlledMedia(candidatePath);
  }

  Future<void> _assertControlledMedia(String candidatePath) async {
    final root = await _mediaDirectoryProvider();
    final normalizedRoot = p.normalize(p.absolute(root.path));
    final normalizedCandidate = p.normalize(p.absolute(candidatePath));
    if (!p.isWithin(normalizedRoot, normalizedCandidate)) {
      throw ArgumentError.value(
        candidatePath,
        'controlledLocalPath',
        '图片必须先复制到应用受控目录。',
      );
    }
    if (await FileSystemEntity.type(normalizedCandidate, followLinks: false) !=
        FileSystemEntityType.file) {
      throw ArgumentError.value(
        candidatePath,
        'controlledLocalPath',
        '受控图片不存在或不是普通文件。',
      );
    }
  }

  static ImportMediaReference _copyMedia(
    ImportMediaReference item, {
    int? position,
    bool? ignored,
    ImportMediaOcrStatus? ocrStatus,
    String? ocrErrorCode,
    String? ocrErrorMessage,
  }) {
    return ImportMediaReference(
      id: item.id,
      localPath: item.localPath,
      originalLocalPath: item.originalLocalPath,
      contentRevision: item.contentRevision,
      position: position ?? item.position,
      rotationQuarterTurns: item.rotationQuarterTurns,
      ignored: ignored ?? item.ignored,
      ocrText: item.ocrText,
      ocrPage: item.ocrPage,
      ocrStatus: ocrStatus ?? item.ocrStatus,
      ocrErrorCode: ocrErrorCode ?? item.ocrErrorCode,
      ocrErrorMessage: ocrErrorMessage ?? item.ocrErrorMessage,
    );
  }

  Future<void> _deleteControlledMedia(String candidatePath) async {
    try {
      final root = await _mediaDirectoryProvider();
      final normalizedRoot = p.normalize(p.absolute(root.path));
      final normalizedCandidate = p.normalize(p.absolute(candidatePath));
      if (!p.isWithin(normalizedRoot, normalizedCandidate)) return;
      final type = await FileSystemEntity.type(
        normalizedCandidate,
        followLinks: false,
      );
      if (type != FileSystemEntityType.file) return;
      final resolvedRoot = await root.resolveSymbolicLinks();
      final resolvedCandidate = await File(
        normalizedCandidate,
      ).resolveSymbolicLinks();
      if (!p.isWithin(resolvedRoot, resolvedCandidate)) return;
      await File(normalizedCandidate).delete();
      final parent = File(normalizedCandidate).parent;
      if (p.isWithin(normalizedRoot, parent.path) &&
          await parent.list().isEmpty) {
        await parent.delete();
      }
    } on FileSystemException catch (error, stackTrace) {
      // 删除记录已经成功；清理失败留给下一次机会式孤立文件清理，但只屏蔽
      // 文件系统错误并保留诊断日志。
      developer.log(
        'controlled_media_delete_failed',
        name: 'kitchen_import_data',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<Directory> _defaultMediaDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'import_media'));
  }
}
