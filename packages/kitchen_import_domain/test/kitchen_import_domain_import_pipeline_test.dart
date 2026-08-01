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
