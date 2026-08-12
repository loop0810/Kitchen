import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  testWidgets('繁体默认保留并提供建议拒绝、转换预览和撤销入口', (tester) async {
    tester.view.physicalSize = const Size(420, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _OcrQualityRepository();
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
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const ImportTaskPage(taskId: 'quality-task'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('馬鈴薯 1O克'), findsWidgets);
    expect(find.text('识别文字需要校对'), findsOneWidget);
    expect(find.textContaining('第 1 张'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byTooltip('拒绝这条建议'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byTooltip('拒绝这条建议'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('拒绝这条建议'), findsOneWidget);
    await tester.tap(find.byTooltip('拒绝这条建议'));
    await tester.pump();
    expect(repository.rejectedSuggestionId, 'suggestion-1');

    await tester.scrollUntilVisible(
      find.text('转换为简体'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('转换为简体'));
    await tester.pumpAndSettle();
    expect(find.text('预览转换为简体'), findsOneWidget);
    expect(find.text('转换前'), findsOneWidget);
    expect(find.text('转换后'), findsOneWidget);
    expect(find.textContaining('马铃薯 1O克'), findsOneWidget);
    await tester.tap(find.text('确认转换'));
    await tester.pumpAndSettle();
    expect(repository.savedKind, OcrCorrectionRevisionKind.convertToSimplified);
    expect(repository.savedText, contains('马铃薯'));

    await tester.scrollUntilVisible(
      find.text('撤销上次校对'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('撤销上次校对'));
    await tester.pumpAndSettle();
    expect(repository.undoCalled, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _OcrQualityRepository implements ImportTaskRepository {
  final task = ImportTaskEntity(
    id: 'quality-task',
    inputKind: ImportInputKind.pastedText,
    status: ImportTaskStatus.awaitingReview,
    originalText: '馬鈴薯 1O克',
    media: const [],
    ocrText: '馬鈴薯 1O克',
    ocrQuality: ImportOcrQualityState(
      textQuality: OcrTextQualityReport(
        level: OcrTextQualityLevel.needsAttention,
        issues: [OcrTextQualityIssueCode.garbledText],
        evidence: [
          OcrTextQualityEvidence(
            pageIndex: 0,
            lineId: 'line-1',
            issue: OcrTextQualityIssueCode.garbledText,
            message: '用量数字可能识别不准。',
          ),
        ],
        profileVersion: '1',
      ),
      suggestions: [
        OcrCorrectionSuggestion(
          id: 'suggestion-1',
          originalText: 'O',
          replacementText: '0',
          reason: OcrCorrectionReason.number,
          pageIndex: 0,
          lineId: 'line-1',
        ),
      ],
      revisions: [
        OcrCorrectionRevision(
          id: 'revision-1',
          beforeText: '馬鈴薯 10克',
          afterText: '馬鈴薯 1O克',
          kind: OcrCorrectionRevisionKind.manual,
          createdAt: DateTime(2026),
        ),
      ],
    ),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  String? rejectedSuggestionId;
  String? savedText;
  OcrCorrectionRevisionKind? savedKind;
  var undoCalled = false;

  @override
  Stream<List<ImportTaskEntity>> watchTasks() => Stream.value([task]);

  @override
  Future<ImportTaskEntity?> getTask(String taskId) async => task;

  @override
  Future<void> rejectOcrCorrectionSuggestion(
    String taskId,
    String suggestionId,
  ) async {
    rejectedSuggestionId = suggestionId;
  }

  @override
  Future<void> saveOcrCorrectionRevision({
    required String taskId,
    required String text,
    required OcrCorrectionRevisionKind kind,
  }) async {
    savedText = text;
    savedKind = kind;
  }

  @override
  Future<void> undoLastOcrCorrection(String taskId) async {
    undoCalled = true;
  }

  @override
  Future<void> updateStatus(
    String taskId,
    ImportTaskStatus status, {
    int? expectedGeneration,
  }) async {}

  @override
  Future<void> saveDraft(
    String taskId,
    RecipeDraftEntity draft, {
    int? expectedGeneration,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
