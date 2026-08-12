import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ocr_quality_benchmark.dart';

void main() {
  test('图片级 benchmark manifest、图片和参考结果可重复通过预算', () async {
    final root = _fixtureRoot();
    final first = await runOcrQualityBenchmark(
      manifestFile: File('$root/manifest.json'),
      resultsFile: File('$root/results/reference-ground-truth.json'),
      budgetsFile: File('$root/budgets.json'),
    );
    final second = await runOcrQualityBenchmark(
      manifestFile: File('$root/manifest.json'),
      resultsFile: File('$root/results/reference-ground-truth.json'),
      budgetsFile: File('$root/budgets.json'),
    );

    expect(first['passed'], isTrue);
    expect(first['sampleCount'], 10);
    expect(first['aggregate'], second['aggregate']);
    expect(
      (first['byTrait']! as Map).keys,
      containsAll(<String>{
        'clear',
        'blurred',
        'smallText',
        'lowContrast',
        'rotated',
        'multiColumn',
        'excessChrome',
        'traditional',
        'mixedScript',
        'landscape',
      }),
    );
  });
}

String _fixtureRoot() {
  final candidates = [
    'test/fixtures/ocr_benchmark',
    'packages/kitchen_import_domain/test/fixtures/ocr_benchmark',
  ];
  return candidates.firstWhere(
    (path) => Directory(path).existsSync(),
    orElse: () => throw StateError('找不到 OCR benchmark fixture 目录'),
  );
}
