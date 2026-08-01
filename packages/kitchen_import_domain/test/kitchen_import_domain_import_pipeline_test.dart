import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  test('OCR 期间删除任务会安全终止且不回写失败状态', () async {
    final repository = _DeletingImportTaskRepository();
    final ocr = _SuspendedOcrAdapter();
    final pipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
      ocrAdapter: ocr,
    );

    final processing = pipeline.process('task-1');
    await ocr.started.future;
    await repository.delete('task-1');
    ocr.result.complete('番茄炒蛋');

    await expectLater(processing, completes);
    expect(await repository.getTask('task-1'), isNull);
  });

  test('多张图片按 position 合并 OCR 并生成菜谱草稿', () async {
    final repository = _MemoryImportTaskRepository(
      media: const [
        ImportMediaReference(id: 'page-2', localPath: '2.jpg', position: 1),
        ImportMediaReference(id: 'page-1', localPath: '1.jpg', position: 0),
      ],
    );
    final pipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
      ocrAdapter: _MappedOcrAdapter(const {
        'page-1': '番茄炒蛋\n食材\n番茄 2个\n鸡蛋 3个',
        'page-2': '步骤\n1\n番茄切块\n2\n鸡蛋炒熟',
      }),
    );

    await pipeline.process('task-1');

    expect(repository.task.ocrText, startsWith('番茄炒蛋'));
    expect(repository.task.draft!.ingredients.value, ['番茄 2个', '鸡蛋 3个']);
    expect(repository.task.draft!.steps.value, ['番茄切块', '鸡蛋炒熟']);
    expect(repository.task.status, ImportTaskStatus.awaitingReview);
  });

  test('OCR 未识别到文字时保留任务并给出可行动错误', () async {
    final repository = _MemoryImportTaskRepository(
      media: const [
        ImportMediaReference(id: 'page-1', localPath: '1.jpg', position: 0),
      ],
    );
    final pipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
      ocrAdapter: _MappedOcrAdapter(const {'page-1': '  '}),
    );

    await pipeline.process('task-1');

    expect(repository.task.status, ImportTaskStatus.failed);
    expect(repository.task.errorCode, 'imageUnreadable');
    expect(repository.task.errorMessage, contains('更换图片'));
  });

  test('用户校对 OCR 后只重新结构化且保留原始图片', () async {
    final repository = _MemoryImportTaskRepository(
      media: const [
        ImportMediaReference(id: 'page-1', localPath: '1.jpg', position: 0),
      ],
    );
    final pipeline = ImportPipeline(
      repository: repository,
      localStructurer: const LocalRecipeStructurerService(),
    );

    await pipeline.restructureFromOcrText(
      'task-1',
      '葱油拌面\n食材\n面条\n100克\n步骤\n煮熟面条',
    );

    expect(repository.task.media.single.localPath, '1.jpg');
    expect(repository.task.ocrText, contains('葱油拌面'));
    expect(repository.task.draft!.ingredients.value, ['面条 100克']);
  });
}

class _MappedOcrAdapter implements OcrAdapter {
  const _MappedOcrAdapter(this.values);

  final Map<String, String> values;

  @override
  Future<String> recognize(ImportMediaReference media) async {
    return values[media.id] ?? '';
  }
}

class _MemoryImportTaskRepository implements ImportTaskRepository {
  _MemoryImportTaskRepository({required List<ImportMediaReference> media})
    : task = ImportTaskEntity(
        id: 'task-1',
        inputKind: ImportInputKind.images,
        status: ImportTaskStatus.queued,
        originalText: '',
        media: media,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  ImportTaskEntity task;

  @override
  Future<ImportTaskEntity?> getTask(String taskId) async => task;

  @override
  Future<void> updateStatus(String taskId, ImportTaskStatus status) async {
    task = _copy(status: status, clearError: true);
  }

  @override
  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required String text,
  }) async {
    task = _copy(
      media: task.media
          .map(
            (item) => item.id == mediaId
                ? ImportMediaReference(
                    id: item.id,
                    localPath: item.localPath,
                    position: item.position,
                    ocrText: text,
                    ocrCompleted: true,
                  )
                : item,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> saveOcrText(String taskId, String text) async {
    task = _copy(ocrText: text);
  }

  @override
  Future<void> saveDraft(String taskId, RecipeDraftEntity draft) async {
    task = _copy(status: ImportTaskStatus.awaitingReview, draft: draft);
  }

  @override
  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
  }) async {
    task = _copy(
      status: ImportTaskStatus.failed,
      errorCode: code,
      errorMessage: message,
    );
  }

  ImportTaskEntity _copy({
    ImportTaskStatus? status,
    List<ImportMediaReference>? media,
    String? ocrText,
    RecipeDraftEntity? draft,
    String? errorCode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImportTaskEntity(
      id: task.id,
      inputKind: task.inputKind,
      status: status ?? task.status,
      originalText: task.originalText,
      media: media ?? task.media,
      ocrText: ocrText ?? task.ocrText,
      draft: draft ?? task.draft,
      errorCode: clearError ? null : errorCode ?? task.errorCode,
      errorMessage: clearError ? null : errorMessage ?? task.errorMessage,
      createdAt: task.createdAt,
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SuspendedOcrAdapter implements OcrAdapter {
  final Completer<void> started = Completer<void>();
  final Completer<String> result = Completer<String>();

  @override
  Future<String> recognize(ImportMediaReference media) {
    started.complete();
    return result.future;
  }
}

class _DeletingImportTaskRepository implements ImportTaskRepository {
  ImportTaskEntity? _task = ImportTaskEntity(
    id: 'task-1',
    inputKind: ImportInputKind.images,
    status: ImportTaskStatus.queued,
    originalText: '',
    media: const [
      ImportMediaReference(
        id: 'media-1',
        localPath: 'controlled.jpg',
        position: 0,
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<ImportTaskEntity?> getTask(String taskId) async => _task;

  @override
  Future<void> updateStatus(String taskId, ImportTaskStatus status) async {
    if (_task == null) throw StateError('deleted');
  }

  @override
  Future<void> saveMediaOcr({
    required String taskId,
    required String mediaId,
    required String text,
  }) async {
    if (_task == null) throw StateError('deleted');
  }

  @override
  Future<void> fail({
    required String taskId,
    required String code,
    required String message,
  }) async {
    if (_task == null) {
      throw StateError('deleted');
    }
  }

  @override
  Future<void> delete(String taskId) async => _task = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
