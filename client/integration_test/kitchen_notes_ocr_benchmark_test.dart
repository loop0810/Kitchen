import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kitchen_import_data/kitchen_import_data.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

const _sampleIds = [
  'clear-hans',
  'blurred-hans',
  'small-text-hans',
  'low-contrast-hans',
  'rotated-hans',
  'multi-column-hans',
  'chrome-noise-hans',
  'traditional-hant',
  'mixed-script',
  'landscape-hans',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android 真机采集原图基线和当前 OCR 结果', (tester) async {
    await tester.runAsync(() async {
      const root = String.fromEnvironment('OCR_BENCHMARK_ROOT');
      if (root.isEmpty) {
        fail('缺少 OCR_BENCHMARK_ROOT dart-define');
      }
      final module = ImportDataModule();
      final baseline = <Map<String, Object?>>[];
      final optimized = <Map<String, Object?>>[];
      try {
        for (final (index, id) in _sampleIds.indexed) {
          final path = '$root/$id.png';
          expect(File(path).existsSync(), isTrue, reason: '真机缺少 $id');
          final media = ImportMediaReference(
            id: id,
            localPath: path,
            position: index,
          );

          final baselineCapture = await _measure(() async {
            final page = await module.ocrAdapter.recognize(media);
            return _structure(page);
          });
          baseline.add(_sampleResult(id, baselineCapture));

          final optimizedCapture = await _measure(() async {
            final preparation = await module.ocrInputPreparer.prepare(media);
            try {
              final original = await module.ocrAdapter.recognize(
                _candidateMedia(media, preparation.original),
              );
              var selected = original;
              var selectedSource = preparation.original.source.name;
              final diagnostics = <String, Object?>{
                'originalText': original.plainText,
                'imageQualityIssues': [
                  for (final issue in preparation.imageQuality.issues)
                    issue.name,
                ],
              };
              final enhancedCandidate = preparation.enhanced;
              if (enhancedCandidate != null) {
                final enhanced = await module.ocrAdapter.recognize(
                  _candidateMedia(media, enhancedCandidate),
                );
                diagnostics['enhancedText'] = enhanced.plainText;
                if (const OcrCandidateSelectorService().shouldSelectEnhanced(
                  original: original,
                  enhanced: enhanced,
                )) {
                  selected = enhanced;
                  selectedSource = enhancedCandidate.source.name;
                }
              }
              return _structure(
                selected,
                selectedSource: selectedSource,
                candidateDiagnostics: diagnostics,
              );
            } finally {
              await module.ocrInputPreparer.release(preparation);
            }
          });
          optimized.add(_sampleResult(id, optimizedCapture));
        }

        final engine = optimized.first['engine'] as String;
        final engineVersion = optimized.first['engineVersion'] as String?;
        await _writeResults(
          '$root/baseline-results.json',
          preprocessVersion: 'none',
          engine: engine,
          engineVersion: engineVersion,
          samples: baseline,
        );
        await _writeResults(
          '$root/post-change-results.json',
          preprocessVersion: 'conservative-text-enhancement/1',
          engine: engine,
          engineVersion: engineVersion,
          samples: optimized,
        );
        const holdSeconds = int.fromEnvironment('OCR_BENCHMARK_HOLD_SECONDS');
        // 真机测试结束后 Flutter 会卸载临时 APK；留出受控窗口让宿主机通过
        // `run-as` 拉取匿名报告，默认测试和 CI 不额外等待。
        if (holdSeconds > 0) {
          // ignore: avoid_print
          print('OCR_BENCHMARK_RESULTS_READY');
          await Future<void>.delayed(Duration(seconds: holdSeconds));
        }
      } finally {
        await module.close();
      }
    });
  });
}

ImportMediaReference _candidateMedia(
  ImportMediaReference source,
  OcrInputCandidate candidate,
) {
  return ImportMediaReference(
    id: source.id,
    localPath: candidate.localPath,
    position: source.position,
    contentRevision: source.contentRevision,
  );
}

Future<_MeasuredCapture> _measure(
  Future<_StructuredCapture> Function() run,
) async {
  final initialMemoryBytes = ProcessInfo.currentRss;
  var peakMemoryBytes = initialMemoryBytes;
  final timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
    final current = ProcessInfo.currentRss;
    if (current > peakMemoryBytes) peakMemoryBytes = current;
  });
  final stopwatch = Stopwatch()..start();
  try {
    final capture = await run();
    stopwatch.stop();
    return _MeasuredCapture(
      capture: capture,
      durationMs: stopwatch.elapsedMilliseconds,
      peakMemoryBytes: peakMemoryBytes > initialMemoryBytes
          ? peakMemoryBytes - initialMemoryBytes
          : 0,
    );
  } finally {
    timer.cancel();
  }
}

_StructuredCapture _structure(
  OcrPageEntity page, {
  String selectedSource = 'original',
  Map<String, Object?> candidateDiagnostics = const {},
}) {
  final document = OcrDocumentEntity(pages: [page]);
  final layout = const OcrLayoutAnalyzerService().analyze(document);
  final draft = const LocalRecipeStructurerService().structure(
    text: '',
    source: SourceSnapshot(originalText: ''),
    ocrDocument: document,
  );
  return _StructuredCapture(
    page: page,
    filteredLines: [for (final item in layout.visibleLines) item.line.text],
    title: draft.title.value,
    ingredients: draft.ingredients.value,
    steps: draft.steps.value,
    selectedSource: selectedSource,
    candidateDiagnostics: candidateDiagnostics,
  );
}

Map<String, Object?> _sampleResult(String id, _MeasuredCapture measured) {
  final capture = measured.capture;
  return {
    'id': id,
    'text': capture.page.plainText,
    'filteredLines': capture.filteredLines,
    'structure': {
      'title': capture.title,
      'ingredients': capture.ingredients,
      'steps': capture.steps,
    },
    'durationMs': measured.durationMs,
    'peakMemoryBytes': measured.peakMemoryBytes,
    'selectedSource': capture.selectedSource,
    if (capture.candidateDiagnostics.isNotEmpty)
      'candidateDiagnostics': capture.candidateDiagnostics,
    'engine': capture.page.platformMetadata.engineIdentifier,
    'engineVersion': capture.page.platformMetadata.engineVersion,
  };
}

Future<void> _writeResults(
  String path, {
  required String preprocessVersion,
  required String engine,
  required String? engineVersion,
  required List<Map<String, Object?>> samples,
}) async {
  final value = {
    'schemaVersion': 1,
    'sampleSetVersion': '2026-08-12.1',
    'capture': {
      'platform': 'android',
      'engine': engine,
      'engineVersion': engineVersion,
      'deviceKind': 'physical-android',
      'preprocessVersion': preprocessVersion,
      'capturedAt': '2026-08-12',
    },
    'samples': samples,
  };
  await File(
    path,
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(value)}\n');
}

class _StructuredCapture {
  const _StructuredCapture({
    required this.page,
    required this.filteredLines,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.selectedSource,
    required this.candidateDiagnostics,
  });

  final OcrPageEntity page;
  final List<String> filteredLines;
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final String selectedSource;
  final Map<String, Object?> candidateDiagnostics;
}

class _MeasuredCapture {
  const _MeasuredCapture({
    required this.capture,
    required this.durationMs,
    required this.peakMemoryBytes,
  });

  final _StructuredCapture capture;
  final int durationMs;
  final int peakMemoryBytes;
}
