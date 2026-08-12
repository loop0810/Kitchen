import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final values = _parseArguments(arguments);
  if ({
    'manifest',
    'results',
    'budgets',
  }.difference(values.keys.toSet()).isNotEmpty) {
    stderr.writeln(
      'usage: dart run tool/ocr_quality_benchmark.dart '
      '--manifest <path> --results <path> --budgets <path> [--output <path>]',
    );
    exitCode = 64;
    return;
  }
  final report = await runOcrQualityBenchmark(
    manifestFile: File(values['manifest']!),
    resultsFile: File(values['results']!),
    budgetsFile: File(values['budgets']!),
  );
  const encoder = JsonEncoder.withIndent('  ');
  final encoded = encoder.convert(report);
  final outputPath = values['output'];
  if (outputPath != null) {
    final output = File(outputPath);
    await output.parent.create(recursive: true);
    await output.writeAsString('$encoded\n');
  }
  stdout.writeln(encoded);
  if (report['passed'] != true) exitCode = 1;
}

/// 读取图片级标准答案、一次平台采集结果和质量预算，生成不包含 OCR 正文的匿名报告。
Future<Map<String, Object?>> runOcrQualityBenchmark({
  required File manifestFile,
  required File resultsFile,
  required File budgetsFile,
}) async {
  final manifest = _readObject(manifestFile);
  final results = _readObject(resultsFile);
  final budgets = _readObject(budgetsFile);
  _requireVersion(manifest, 'manifest');
  _requireVersion(results, 'results');
  _requireVersion(budgets, 'budgets');

  final sampleSetVersion = manifest['sampleSetVersion'];
  if (sampleSetVersion != results['sampleSetVersion']) {
    throw FormatException(
      'sampleSetVersion 不一致：manifest=$sampleSetVersion, '
      'results=${results['sampleSetVersion']}',
    );
  }
  final manifestSamples = _objects(manifest['samples'], 'manifest.samples');
  final resultSamples = {
    for (final sample in _objects(results['samples'], 'results.samples'))
      sample['id'] as String: sample,
  };
  final defaultBudget = Map<String, dynamic>.from(
    budgets['default']! as Map<dynamic, dynamic>,
  );
  final sampleReports = <Map<String, Object?>>[];

  for (final sample in manifestSamples) {
    final id = sample['id'] as String;
    final imagePath = sample['imagePath'] as String;
    if (imagePath.startsWith('/') || imagePath.split('/').contains('..')) {
      throw FormatException('$id 的 imagePath 必须是目录内相对路径');
    }
    final image = File('${manifestFile.parent.path}/$imagePath');
    if (!await image.exists()) throw FormatException('$id 缺少图片：$imagePath');
    final actual = resultSamples[id];
    if (actual == null) throw FormatException('results 缺少样本：$id');
    final truth = Map<String, dynamic>.from(
      sample['groundTruth']! as Map<dynamic, dynamic>,
    );
    final structure = Map<String, dynamic>.from(
      actual['structure']! as Map<dynamic, dynamic>,
    );
    final expectedText = truth['text'] as String;
    final actualText = actual['text'] as String;
    final expectedLines = _strings(truth['effectiveLines']);
    final filteredLines = _strings(actual['filteredLines']);
    final noiseLines = _strings(truth['noiseLines']);
    final characterDistance = _editDistance(expectedText, actualText);
    final expectedLength = _runes(expectedText).length;
    final characterErrorRate = expectedLength == 0
        ? (actualText.isEmpty ? 0.0 : 1.0)
        : characterDistance / expectedLength;
    final lineRecall = _recall(expectedLines, filteredLines);
    final noiseResidual = noiseLines.isEmpty
        ? 0.0
        : noiseLines
                  .where((line) => _containsLine(filteredLines, line))
                  .length /
              noiseLines.length;
    final titleExact =
        _normalize(structure['title'] as String) ==
            _normalize(truth['title'] as String)
        ? 1.0
        : 0.0;
    final ingredientF1 = _f1(
      _strings(truth['ingredients']),
      _strings(structure['ingredients']),
    );
    final stepF1 = _f1(_strings(truth['steps']), _strings(structure['steps']));
    final durationMs = (actual['durationMs'] as num).toDouble();
    final peakMemoryBytes = (actual['peakMemoryBytes'] as num).toDouble();
    final metrics = <String, double>{
      'characterErrorRate': characterErrorRate,
      'effectiveLineRecall': lineRecall,
      'noiseResidualRate': noiseResidual,
      'titleExactRate': titleExact,
      'ingredientF1': ingredientF1,
      'stepF1': stepF1,
      'correctionDistanceRate': characterErrorRate,
      'durationMs': durationMs,
      'peakMemoryBytes': peakMemoryBytes,
    };
    final failures = _budgetFailures(metrics, defaultBudget);
    sampleReports.add({
      'id': id,
      'traits': _strings(sample['traits']),
      'metrics': metrics.map((key, value) => MapEntry(key, _rounded(value))),
      'passed': failures.isEmpty,
      'failures': failures,
    });
  }

  final aggregate = <String, double>{};
  for (final key
      in (sampleReports.first['metrics']! as Map).keys.cast<String>()) {
    final values = sampleReports
        .map((sample) => (sample['metrics']! as Map)[key] as num)
        .map((value) => value.toDouble())
        .toList(growable: false);
    aggregate[key] = key == 'durationMs' || key == 'peakMemoryBytes'
        ? values.reduce((left, right) => left > right ? left : right)
        : values.reduce((left, right) => left + right) / values.length;
  }
  final byTrait = <String, List<Map<String, Object?>>>{};
  for (final sample in sampleReports) {
    for (final trait in sample['traits']! as List<String>) {
      byTrait.putIfAbsent(trait, () => []).add(sample);
    }
  }
  final capture = Map<String, dynamic>.from(
    results['capture']! as Map<dynamic, dynamic>,
  );
  return {
    'schemaVersion': 1,
    'sampleSetVersion': sampleSetVersion as String,
    'budgetVersion': budgets['budgetVersion'] as String,
    'capture': {
      'platform': capture['platform'],
      'engine': capture['engine'],
      'engineVersion': capture['engineVersion'],
      'deviceKind': capture['deviceKind'],
      'preprocessVersion': capture['preprocessVersion'],
      'capturedAt': capture['capturedAt'],
    },
    'sampleCount': sampleReports.length,
    'aggregate': aggregate.map((key, value) => MapEntry(key, _rounded(value))),
    'byTrait': byTrait.map(
      (trait, samples) => MapEntry(trait, {
        'sampleCount': samples.length,
        'passed': samples.every((sample) => sample['passed'] == true),
      }),
    ),
    'passed': sampleReports.every((sample) => sample['passed'] == true),
    'samples': sampleReports,
  };
}

Map<String, String> _parseArguments(List<String> arguments) {
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index += 2) {
    final key = arguments[index];
    if (!key.startsWith('--') || index + 1 >= arguments.length) break;
    result[key.substring(2)] = arguments[index + 1];
  }
  return result;
}

Map<String, dynamic> _readObject(File file) {
  if (!file.existsSync()) throw ArgumentError('文件不存在：${file.path}');
  return Map<String, dynamic>.from(
    jsonDecode(file.readAsStringSync()) as Map<dynamic, dynamic>,
  );
}

void _requireVersion(Map<String, dynamic> value, String name) {
  if (value['schemaVersion'] != 1) {
    throw FormatException('$name schemaVersion 必须为 1');
  }
}

List<Map<String, dynamic>> _objects(Object? value, String name) {
  if (value is! List) throw FormatException('$name 必须是数组');
  return value
      .map((item) => Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
      .toList(growable: false);
}

List<String> _strings(Object? value) =>
    (value as List<dynamic>).cast<String>().toList(growable: false);

List<int> _runes(String value) => value.replaceAll('\r\n', '\n').runes.toList();

int _editDistance(String left, String right) {
  final a = _runes(left);
  final b = _runes(right);
  var previous = List<int>.generate(b.length + 1, (index) => index);
  for (var row = 1; row <= a.length; row++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = row;
    for (var column = 1; column <= b.length; column++) {
      final substitution =
          previous[column - 1] + (a[row - 1] == b[column - 1] ? 0 : 1);
      final insertion = current[column - 1] + 1;
      final deletion = previous[column] + 1;
      current[column] = [
        substitution,
        insertion,
        deletion,
      ].reduce((left, right) => left < right ? left : right);
    }
    previous = current;
  }
  return previous.last;
}

String _normalize(String value) =>
    value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

bool _containsLine(List<String> lines, String expected) {
  final needle = _normalize(expected);
  return lines.any((line) {
    final value = _normalize(line);
    return value == needle || value.contains(needle) || needle.contains(value);
  });
}

double _recall(List<String> expected, List<String> actual) {
  if (expected.isEmpty) return 1;
  return expected.where((line) => _containsLine(actual, line)).length /
      expected.length;
}

double _f1(List<String> expected, List<String> actual) {
  final expectedSet = expected.map(_normalize).toSet();
  final actualSet = actual.map(_normalize).toSet();
  if (expectedSet.isEmpty && actualSet.isEmpty) return 1;
  final matched = expectedSet.intersection(actualSet).length;
  final precision = actualSet.isEmpty ? 0.0 : matched / actualSet.length;
  final recall = expectedSet.isEmpty ? 0.0 : matched / expectedSet.length;
  return precision + recall == 0
      ? 0
      : 2 * precision * recall / (precision + recall);
}

List<String> _budgetFailures(
  Map<String, double> metrics,
  Map<String, dynamic> budget,
) {
  final failures = <String>[];
  void maximum(String metric, String key) {
    final limit = (budget[key] as num).toDouble();
    if (metrics[metric]! > limit) failures.add('$metric > $limit');
  }

  void minimum(String metric, String key) {
    final limit = (budget[key] as num).toDouble();
    if (metrics[metric]! < limit) failures.add('$metric < $limit');
  }

  maximum('characterErrorRate', 'maxCharacterErrorRate');
  minimum('effectiveLineRecall', 'minEffectiveLineRecall');
  maximum('noiseResidualRate', 'maxNoiseResidualRate');
  minimum('titleExactRate', 'minTitleExactRate');
  minimum('ingredientF1', 'minIngredientF1');
  minimum('stepF1', 'minStepF1');
  maximum('correctionDistanceRate', 'maxCorrectionDistanceRate');
  maximum('durationMs', 'maxDurationMs');
  maximum('peakMemoryBytes', 'maxPeakMemoryBytes');
  return failures;
}

double _rounded(double value) => double.parse(value.toStringAsFixed(6));
