import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  final fixtures = _loadFixtures();

  test('真实 OCR 回放集覆盖约定的平台与退化场景', () {
    expect(fixtures.map((fixture) => fixture.platform).toSet(), {
      'android',
      'ios',
    });
    expect(fixtures.map((fixture) => fixture.engine).toSet(), {
      'mlKit',
      'vision',
    });
    expect(
      fixtures.expand((fixture) => fixture.traits).toSet(),
      containsAll({
        'blurred',
        'portrait',
        'landscape',
        'multiColumn',
        'stitched',
        'repeatedEdgeChrome',
        'partialFailure',
        'userCorrection',
      }),
    );
    expect(
      fixtures.every((fixture) => fixture.originalImageIncluded == false),
      isTrue,
      reason: '回放集只提交脱敏 OCR 快照，不提交来源平台截图。',
    );
  });

  for (final fixture in fixtures) {
    test('回放 ${fixture.id}', () {
      expect(fixture.succeededPages, isNotEmpty);
      expect(
        fixture.succeededPages.map((page) => page.pageIndex),
        orderedEquals(
          fixture.succeededPages.map((page) => page.pageIndex).toList()..sort(),
        ),
      );

      final document = OcrDocumentEntity(pages: fixture.succeededPages);
      final analysis = const OcrLayoutAnalyzerService().analyze(document);
      final draft = const LocalRecipeStructurerService().structure(
        text: document.plainText,
        source: const SourceSnapshot(originalText: ''),
        ocrDocument: document,
      );

      _expectDraft(draft, fixture.expected);
      for (final excluded in fixture.expected.normalizedTextExcludes) {
        expect(analysis.normalizedText, isNot(contains(excluded)));
      }
      expect(
        analysis.removedChromeLineIds.length,
        greaterThanOrEqualTo(fixture.expected.minimumRemovedChromeLines),
      );
      expect(fixture.failedPageCount, fixture.expected.failedPageCount);

      final correctedText = fixture.correctedText;
      final correctedExpected = fixture.correctedExpected;
      if (correctedText != null && correctedExpected != null) {
        expect(correctedText, isNot(document.plainText));
        final correctedDraft = const LocalRecipeStructurerService().structure(
          text: correctedText,
          source: const SourceSnapshot(originalText: ''),
        );
        _expectDraft(correctedDraft, correctedExpected);
      }
    });
  }
}

void _expectDraft(RecipeDraftEntity draft, _ExpectedReplay expected) {
  if (expected.titleEquals != null) {
    expect(draft.title.value, expected.titleEquals);
  }
  if (expected.titleContains != null) {
    expect(draft.title.value, contains(expected.titleContains));
  }
  expect(draft.ingredients.value, containsAll(expected.ingredientsContain));
  expect(draft.steps.value, containsAll(expected.stepsContain));
  for (final warning in expected.warningsContain) {
    expect(draft.warnings, contains(contains(warning)));
  }
  if (expected.quality != null) {
    expect(draft.quality.name, expected.quality);
  }
}

List<_OcrReplayFixture> _loadFixtures() {
  final directory = _fixtureDirectory();
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  if (files.isEmpty) {
    throw StateError('OCR 回放 fixture 不能为空。');
  }
  return files
      .map(
        (file) => _OcrReplayFixture.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
      )
      .toList(growable: false);
}

Directory _fixtureDirectory() {
  final candidates = [
    Directory('test/fixtures/ocr_replay'),
    Directory('packages/kitchen_import_domain/test/fixtures/ocr_replay'),
  ];
  return candidates.firstWhere(
    (candidate) => candidate.existsSync(),
    orElse: () => throw StateError('找不到 OCR 回放 fixture 目录。'),
  );
}

class _OcrReplayFixture {
  _OcrReplayFixture({
    required this.id,
    required this.platform,
    required this.engine,
    required this.traits,
    required this.originalImageIncluded,
    required this.pages,
    required this.expected,
    required this.correctedText,
    required this.correctedExpected,
  });

  factory _OcrReplayFixture.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('不支持的 OCR 回放 fixture schema。');
    }
    final capture = json['capture'] as Map<String, dynamic>;
    final pages = (json['pages'] as List<dynamic>)
        .map((value) => _ReplayPage.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
    final correctedExpected = json['correctedExpected'];
    return _OcrReplayFixture(
      id: json['id'] as String,
      platform: capture['platform'] as String,
      engine: capture['engine'] as String,
      traits: (capture['traits'] as List<dynamic>).cast<String>(),
      originalImageIncluded: capture['originalImageIncluded'] as bool,
      pages: pages,
      expected: _ExpectedReplay.fromJson(
        json['expected'] as Map<String, dynamic>,
      ),
      correctedText: json['correctedText'] as String?,
      correctedExpected: correctedExpected == null
          ? null
          : _ExpectedReplay.fromJson(correctedExpected as Map<String, dynamic>),
    );
  }

  final String id;
  final String platform;
  final String engine;
  final List<String> traits;
  final bool originalImageIncluded;
  final List<_ReplayPage> pages;
  final _ExpectedReplay expected;
  final String? correctedText;
  final _ExpectedReplay? correctedExpected;

  List<OcrPageEntity> get succeededPages =>
      pages
          .where((page) => page.status == 'succeeded')
          .map((page) => page.page!)
          .toList(growable: false)
        ..sort((left, right) => left.pageIndex.compareTo(right.pageIndex));

  int get failedPageCount =>
      pages.where((page) => page.status == 'failed').length;
}

class _ReplayPage {
  _ReplayPage({required this.status, required this.page});

  factory _ReplayPage.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    final pageJson = json['page'];
    final valid = status == 'succeeded' ? pageJson != null : pageJson == null;
    if (!valid) {
      throw const FormatException('成功页必须携带 OCR page，失败页不得伪造 OCR 结果。');
    }
    return _ReplayPage(
      status: status,
      page: pageJson == null
          ? null
          : _decodePage(pageJson as Map<String, dynamic>),
    );
  }

  final String status;
  final OcrPageEntity? page;
}

OcrPageEntity _decodePage(Map<String, dynamic> json) {
  return OcrPageEntity(
    pageIndex: json['pageIndex'] as int,
    pixelWidth: json['pixelWidth'] as int,
    pixelHeight: json['pixelHeight'] as int,
    lines: (json['lines'] as List<dynamic>)
        .map((value) {
          final line = value as Map<String, dynamic>;
          final box = line['boundingBox'] as Map<String, dynamic>;
          return OcrLineEntity(
            id: line['id'] as String,
            text: line['text'] as String,
            confidence: (line['confidence'] as num?)?.toDouble(),
            boundingBox: OcrRectValueObject(
              left: (box['left'] as num).toDouble(),
              top: (box['top'] as num).toDouble(),
              right: (box['right'] as num).toDouble(),
              bottom: (box['bottom'] as num).toDouble(),
            ),
          );
        })
        .toList(growable: false),
  );
}

class _ExpectedReplay {
  _ExpectedReplay({
    required this.titleEquals,
    required this.titleContains,
    required this.ingredientsContain,
    required this.stepsContain,
    required this.warningsContain,
    required this.normalizedTextExcludes,
    required this.minimumRemovedChromeLines,
    required this.quality,
    required this.failedPageCount,
  });

  factory _ExpectedReplay.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const []).cast<String>();
    return _ExpectedReplay(
      titleEquals: json['titleEquals'] as String?,
      titleContains: json['titleContains'] as String?,
      ingredientsContain: strings('ingredientsContain'),
      stepsContain: strings('stepsContain'),
      warningsContain: strings('warningsContain'),
      normalizedTextExcludes: strings('normalizedTextExcludes'),
      minimumRemovedChromeLines: json['minimumRemovedChromeLines'] as int? ?? 0,
      quality: json['quality'] as String?,
      failedPageCount: json['failedPageCount'] as int? ?? 0,
    );
  }

  final String? titleEquals;
  final String? titleContains;
  final List<String> ingredientsContain;
  final List<String> stepsContain;
  final List<String> warningsContain;
  final List<String> normalizedTextExcludes;
  final int minimumRemovedChromeLines;
  final String? quality;
  final int failedPageCount;
}
