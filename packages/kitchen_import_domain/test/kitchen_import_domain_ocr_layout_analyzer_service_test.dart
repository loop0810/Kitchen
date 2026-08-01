import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  test('通用布局分析按坐标配对左右列并移除跨页固定框架', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('author-0', '示例作者', 0.05, 0.05, 0.30, 0.09),
          _line('title', '酸辣柠檬鸡爪', 0.08, 0.20, 0.70, 0.26),
          _line('header', '用料', 0.08, 0.32, 0.24, 0.37),
          _line('name-1', '鸡爪', 0.08, 0.42, 0.25, 0.47),
          _line('amount-1', '2斤', 0.76, 0.42, 0.90, 0.47),
          _line('name-2', '柠檬', 0.08, 0.51, 0.25, 0.56),
          _line('amount-2', '1个', 0.76, 0.51, 0.90, 0.56),
          _line('footer-0', '说点什么', 0.60, 0.91, 0.88, 0.96),
        ]),
        _page(1, [
          _line('author-1', '示例作者', 0.05, 0.05, 0.30, 0.09),
          _line('step-header', '步骤1', 0.08, 0.20, 0.28, 0.25),
          _line('step', '鸡爪焯水后拌入配料', 0.08, 0.31, 0.85, 0.37),
          _line('footer-1', '说点什么', 0.60, 0.91, 0.88, 0.96),
        ]),
      ],
    );

    final analysis = const OcrLayoutAnalyzerService().analyze(document);

    expect(analysis.normalizedText, contains('鸡爪  2斤'));
    expect(analysis.normalizedText, isNot(contains('示例作者')));
    expect(analysis.normalizedText, isNot(contains('说点什么')));
    expect(analysis.removedChromeLineIds, {
      'author-0',
      'author-1',
      'footer-0',
      'footer-1',
    });
  });

  test('图片草稿保留字段证据并对所有自动结果要求确认', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('title', '酸辣柠檬鸡爪', 0.08, 0.10, 0.70, 0.16),
          _line('header', '用料', 0.08, 0.25, 0.24, 0.30),
          _line('name', '鸡爪', 0.08, 0.36, 0.25, 0.41),
          _line('amount', '2斤', 0.76, 0.36, 0.90, 0.41),
          _line('step-header', '步骤1', 0.08, 0.53, 0.28, 0.58),
          _line('step', '鸡爪焯水后拌入配料', 0.08, 0.64, 0.85, 0.70),
        ]),
      ],
    );

    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(draft.title.value, '酸辣柠檬鸡爪');
    expect(draft.ingredients.value, ['鸡爪 2斤']);
    expect(draft.steps.value, ['鸡爪焯水后拌入配料']);
    expect(draft.quality, RecipeDraftQuality.readyForReview);
    expect(draft.warnings, isEmpty);
    expect(draft.title.needsConfirmation, isTrue);
    expect(draft.ingredients.needsConfirmation, isTrue);
    expect(draft.title.evidence.single.lineId, 'title');
    expect(
      draft.ingredients.evidence.map((item) => item.lineId),
      containsAll(['name', 'amount']),
    );
  });

  test('没有食材分区的拼图做法不会因包含用量而误写为食材', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('chrome', '内容平台', 0.04, 0.02, 0.20, 0.04),
          _line('title', '剁椒牛肉', 0.30, 0.18, 0.72, 0.27),
          _line(
            'instruction-1',
            '牛肉切片加生抽、料酒、淀粉各1勺抓匀腌15分钟',
            0.08,
            0.42,
            0.92,
            0.47,
          ),
          _line('instruction-2', '放蒜末炒香再倒入牛肉翻炒', 0.08, 0.56, 0.82, 0.61),
        ]),
      ],
    );

    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(draft.title.value, '剁椒牛肉');
    expect(draft.ingredients.value, isEmpty);
    expect(draft.steps.value, hasLength(2));
    expect(draft.quality, RecipeDraftQuality.partial);
    expect(draft.warnings, contains(contains('未找到可靠食材清单')));
    expect(draft.warnings, contains(contains('没有明确标注步骤区')));
  });
}

OcrPageEntity _page(int pageIndex, List<OcrLineEntity> lines) {
  return OcrPageEntity(
    pageIndex: pageIndex,
    pixelWidth: 1000,
    pixelHeight: 2000,
    lines: lines,
  );
}

OcrLineEntity _line(
  String id,
  String text,
  double left,
  double top,
  double right,
  double bottom,
) {
  return OcrLineEntity(
    id: id,
    text: text,
    confidence: 0.95,
    boundingBox: OcrRectValueObject(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    ),
  );
}
