import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  testWidgets('窄屏大文字下展示分页失败和可恢复操作', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MediaRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importDependenciesProvider.overrideWithValue(
            ImportDependencies(
              repository: repository,
              pipeline: ImportPipeline(
                repository: repository,
                localStructurer: const LocalRecipeStructurerService(),
              ),
              persistPickedImages: (paths) async => paths,
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const ImportTaskPage(taskId: 'task-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('未识别到清晰文字'), findsOneWidget);
    expect(find.byTooltip('替换图片'), findsNWidgets(2));
    expect(find.byTooltip('裁剪图片'), findsNWidgets(2));
    expect(find.byTooltip('顺时针旋转 90 度'), findsNWidgets(2));
    expect(find.byTooltip('仅重试这张图片'), findsNothing);
    expect(find.textContaining('不参与整理'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('顺时针旋转 90 度').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('原内容已保留'), findsOneWidget);

    final dragHandle = find.byTooltip('拖动调整顺序').first;
    await tester.timedDrag(
      dragHandle,
      const Offset(320, 0),
      const Duration(seconds: 2),
    );
    await tester.pumpAndSettle();
    expect(repository.reordered, ['media-2', 'media-1']);
  });
}

class _MediaRepository implements ImportTaskRepository {
  final task = ImportTaskEntity(
    id: 'task-1',
    inputKind: ImportInputKind.images,
    status: ImportTaskStatus.failed,
    originalText: '',
    media: const [
      ImportMediaReference(
        id: 'media-1',
        localPath: '/not-found.jpg',
        position: 0,
        ignored: true,
        ocrStatus: ImportMediaOcrStatus.failed,
        ocrErrorCode: 'pageUnreadable',
        ocrErrorMessage: '这张图片未识别成功',
      ),
      ImportMediaReference(
        id: 'media-2',
        localPath: '/also-not-found.jpg',
        position: 1,
        ignored: true,
      ),
    ],
    errorCode: 'imageUnreadable',
    errorMessage: '未识别到清晰文字',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  List<String>? reordered;

  @override
  Stream<List<ImportTaskEntity>> watchTasks() => Stream.value([task]);

  @override
  Future<ImportTaskEntity?> getTask(String taskId) async {
    return reordered == null ? task : null;
  }

  @override
  Future<void> rotateMedia(String taskId, String mediaId) async {
    throw StateError('simulated failure');
  }

  @override
  Future<void> reorderMedia(String taskId, List<String> orderedMediaIds) async {
    reordered = orderedMediaIds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
