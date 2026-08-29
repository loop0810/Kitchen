import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  testWidgets('导入箱展示原型空状态', (tester) async {
    final repository = _EmptyImportTaskRepository();
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
        child: const MaterialApp(home: ImportInboxPage()),
      ),
    );
    await tester.pump();

    expect(find.text('导入箱'), findsOneWidget);
    expect(find.text('把纸上与屏幕里的好味道收好'), findsOneWidget);
    expect(find.text('导入箱还是空的'), findsOneWidget);
    expect(find.text('暂时没有导入任务，新的识别进度会在\n这里整理。'), findsOneWidget);
    expect(find.text('创建菜谱'), findsNothing);
  });

  testWidgets('处理中任务侧滑删除会先确认，取消确认不改变任务', (tester) async {
    final repository = _TaskImportRepository(ImportTaskStatus.structuring);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.drag(find.text('番茄炒蛋'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('删除'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.textContaining('处理会停止'), findsOneWidget);
    await tester.tap(find.text('保留'));
    await tester.pumpAndSettle();

    expect(repository.deleted, isFalse);
    expect(repository.cancelled, isFalse);
  });

  testWidgets('已保存任务确认文案明确不删除正式菜谱', (tester) async {
    final repository = _TaskImportRepository(ImportTaskStatus.saved);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.drag(find.text('番茄炒蛋'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.textContaining('不会删除已经保存到菜谱库'), findsOneWidget);
  });
}

Widget _app(ImportTaskRepository repository) => ProviderScope(
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
  child: const MaterialApp(home: ImportInboxPage()),
);

class _EmptyImportTaskRepository implements ImportTaskRepository {
  @override
  Stream<List<ImportTaskEntity>> watchTasks() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TaskImportRepository implements ImportTaskRepository {
  _TaskImportRepository(ImportTaskStatus status)
    : task = ImportTaskEntity(
        id: 'task-1',
        inputKind: ImportInputKind.pastedText,
        status: status,
        originalText: '番茄炒蛋',
        media: const [],
        finalRecipeId: status == ImportTaskStatus.saved ? 'recipe-1' : null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  final ImportTaskEntity task;
  bool deleted = false;
  bool cancelled = false;

  @override
  Stream<List<ImportTaskEntity>> watchTasks() => Stream.value([task]);
  @override
  Future<void> cancel(String taskId) async => cancelled = true;
  @override
  Future<void> delete(String taskId) async => deleted = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
