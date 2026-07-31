import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  testWidgets('导入箱展示任务空状态与统一创建入口', (tester) async {
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
    expect(find.text('导入任务会出现在这里'), findsOneWidget);
    expect(find.text('创建食谱'), findsOneWidget);
    expect(find.byTooltip('创建食谱'), findsOneWidget);
  });
}

class _EmptyImportTaskRepository implements ImportTaskRepository {
  @override
  Stream<List<ImportTaskEntity>> watchTasks() => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
