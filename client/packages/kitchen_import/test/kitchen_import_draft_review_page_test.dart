import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  testWidgets('审核页展示来源与全部分区，编辑后自动暂存', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ReviewRepository(_task());
    addTearDown(repository.dispose);

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
          home: ImportDraftReviewPage(
            taskId: 'task-1',
            categories: _categories,
            tags: _tags,
            difficulties: _difficulties,
            onContinue: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('问题摘要'), findsOneWidget);
    expect(find.text('基础信息 · 菜名'), findsOneWidget);
    expect(find.textContaining('新识别候选'), findsOneWidget);
    await tester.tap(find.byTooltip('查看来源证据').first);
    await tester.pumpAndSettle();
    expect(find.text('番茄炒蛋'), findsWidgets);
    expect(find.textContaining('第 1 张'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('食材'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('食材'), findsOneWidget);
    final ingredientCard = find.ancestor(
      of: find.text('食材'),
      matching: find.byType(Card),
    );
    final ingredientDragHandle = find
        .descendant(
          of: ingredientCard,
          matching: find.byIcon(Icons.drag_indicator_rounded),
        )
        .first;
    await tester.ensureVisible(ingredientDragHandle);
    await tester.pumpAndSettle();
    await tester.timedDrag(
      ingredientDragHandle,
      const Offset(0, 110),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(repository.savedDraft!.ingredients.value, ['鸡蛋 3个', '番茄 2个']);
    await tester.scrollUntilVisible(
      find.text('准备工作'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('准备工作'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('基础信息 · 菜名'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).first, '我的番茄炒蛋');
    await tester.pump();
    expect(repository.savedDraft!.title.value, '我的番茄炒蛋');
    expect(repository.savedDraft!.title.origin, DraftFieldOrigin.userEdited);
  });

  testWidgets('流水线刷新后补全未编辑字段且不覆盖用户输入', (tester) async {
    final repository = _ReviewRepository(
      _task(title: '', ingredients: const [], steps: const ['已有步骤']),
    );
    addTearDown(repository.dispose);

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
          home: ImportDraftReviewPage(
            taskId: 'task-1',
            categories: _categories,
            tags: _tags,
            difficulties: _difficulties,
            onContinue: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );

    repository.emit(_task());
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '番茄炒蛋',
    );
    await tester.scrollUntilVisible(
      find.text('食材'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('番茄 2个'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('基础信息 · 菜名'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).first, '我的菜名');
    repository.emit(_task(title: '新识别菜名', ingredients: const ['豆腐 1块']));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '我的菜名',
    );
    await tester.scrollUntilVisible(
      find.text('食材'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('豆腐 1块'), findsOneWidget);
  });

  testWidgets('配置字段使用缓存选项，时间使用小时分钟双列选择器', (tester) async {
    final repository = _ReviewRepository(_task());
    addTearDown(repository.dispose);

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
          home: ImportDraftReviewPage(
            taskId: 'task-1',
            categories: _categories,
            tags: _tags,
            difficulties: _difficulties,
            onContinue: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder fieldCard(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(Card));

    expect(
      find.descendant(
        of: fieldCard('分类'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('标签'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: fieldCard('标签'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
      findsOneWidget,
    );
    expect(find.text('管理分类、标签与难度'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('份量（人）'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final servingsPicker = tester.widget<DropdownButton<int>>(
      find.descendant(
        of: fieldCard('份量（人）'),
        matching: find.byType(DropdownButton<int>),
      ),
    );
    expect(servingsPicker.items, hasLength(10));

    await tester.scrollUntilVisible(
      find.text('准备时间'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final prepTimePicker = find.byKey(const ValueKey('prepMinutes-5'));
    await tester.ensureVisible(prepTimePicker);
    await tester.pumpAndSettle();
    await tester.tap(prepTimePicker);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('duration-hours-picker')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('duration-minutes-picker')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('duration-minutes-picker')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('完成'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('难度'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: fieldCard('难度'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
      findsOneWidget,
    );
  });

  testWidgets('确认页分开显示菜谱结构与 OCR 文字风险证据', (tester) async {
    final repository = _ReviewRepository(
      _task(
        ocrQuality: const ImportOcrQualityState(
          textQuality: OcrTextQualityReport(
            level: OcrTextQualityLevel.needsAttention,
            issues: [OcrTextQualityIssueCode.lowConfidenceKeyText],
            evidence: [
              OcrTextQualityEvidence(
                pageIndex: 1,
                lineId: 'line-risk',
                issue: OcrTextQualityIssueCode.lowConfidenceKeyText,
                message: '食材用量可能识别不准。',
              ),
            ],
            profileVersion: '1',
          ),
        ),
      ),
    );
    addTearDown(repository.dispose);
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
          home: ImportDraftReviewPage(
            taskId: 'task-1',
            categories: _categories,
            tags: _tags,
            difficulties: _difficulties,
            onContinue: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('菜谱结构'), findsOneWidget);
    expect(find.text('识别文字'), findsOneWidget);
    expect(find.textContaining('第 2 张 · line-risk'), findsOneWidget);
    expect(find.textContaining('食材用量可能识别不准'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}

const _categories = ['家常菜', '主食'];
const _tags = ['快手', '下饭'];
const _difficulties = ['入门', '简单', '中等', '难'];

ImportTaskEntity _task({
  String title = '番茄炒蛋',
  List<String> ingredients = const ['番茄 2个', '鸡蛋 3个'],
  List<String> steps = const ['番茄切块', '炒熟鸡蛋'],
  ImportOcrQualityState ocrQuality = const ImportOcrQualityState(),
}) => ImportTaskEntity(
  id: 'task-1',
  inputKind: ImportInputKind.images,
  status: ImportTaskStatus.awaitingReview,
  originalText: '',
  media: const [],
  ocrQuality: ocrQuality,
  draft: RecipeDraftEntity(
    warnings: const ['请确认菜名'],
    title: DraftFieldValue(
      value: title,
      origin: DraftFieldOrigin.source,
      confidence: DraftConfidenceLevel.high,
      evidence: const [
        DraftFieldEvidence(pageIndex: 0, lineId: 'line-1', excerpt: '番茄炒蛋'),
      ],
      conflictCandidate: '西红柿炒鸡蛋',
    ),
    summary: const DraftFieldValue(
      value: '',
      origin: DraftFieldOrigin.inferred,
      confidence: DraftConfidenceLevel.low,
    ),
    category: const DraftFieldValue(
      value: '家常菜',
      origin: DraftFieldOrigin.inferred,
    ),
    servings: const DraftFieldValue(value: 2, origin: DraftFieldOrigin.source),
    prepMinutes: const DraftFieldValue(
      value: 5,
      origin: DraftFieldOrigin.source,
    ),
    cookMinutes: const DraftFieldValue(
      value: 10,
      origin: DraftFieldOrigin.source,
    ),
    difficulty: const DraftFieldValue(
      value: '简单',
      origin: DraftFieldOrigin.inferred,
    ),
    tags: const DraftFieldValue(
      value: ['快手'],
      origin: DraftFieldOrigin.inferred,
    ),
    ingredients: DraftFieldValue(
      value: ingredients,
      origin: DraftFieldOrigin.source,
    ),
    preparations: const DraftFieldValue(
      value: ['鸡蛋打散'],
      origin: DraftFieldOrigin.source,
    ),
    steps: DraftFieldValue(value: steps, origin: DraftFieldOrigin.source),
    sourceSnapshot: const SourceSnapshot(originalText: ''),
  ),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _ReviewRepository implements ImportTaskRepository {
  _ReviewRepository(this.task);

  ImportTaskEntity task;
  final _updates = StreamController<List<ImportTaskEntity>>.broadcast();
  RecipeDraftEntity? savedDraft;

  @override
  Stream<List<ImportTaskEntity>> watchTasks() async* {
    yield [task];
    yield* _updates.stream;
  }

  void emit(ImportTaskEntity value) {
    task = value;
    _updates.add([value]);
  }

  Future<void> dispose() => _updates.close();

  @override
  Future<void> saveReviewDraft(String taskId, RecipeDraftEntity draft) async {
    savedDraft = draft;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
