import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  test('候选比较仅在增强结果明确改善且未新增噪声时选择增强', () {
    const selector = OcrCandidateSelectorService();
    final weak = _page(['番茄妙旦', '□', '。'], confidence: 0.3);
    final strong = _page([
      '番茄炒蛋',
      '食材',
      '番茄 2个',
      '鸡蛋 3个',
      '步骤',
      '番茄切块',
    ], confidence: 0.92);

    expect(
      selector.shouldSelectEnhanced(original: weak, enhanced: strong),
      isTrue,
    );
    expect(
      selector.shouldSelectEnhanced(original: strong, enhanced: weak),
      isFalse,
    );
  });

  test('文字质量与菜谱结构质量分别判断', () {
    const quality = OcrTextQualityService();
    final clearButIncomplete = OcrDocumentEntity(
      pages: [
        _page(['清炒时蔬'], confidence: 0.98),
      ],
    );
    final textReport = quality.assessDocument(clearButIncomplete);
    final draft = const LocalRecipeStructurerService().structure(
      text: clearButIncomplete.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: clearButIncomplete,
    );

    expect(textReport.level, OcrTextQualityLevel.usable);
    expect(draft.quality, isNot(RecipeDraftQuality.readyForReview));

    final riskyButStructured = OcrDocumentEntity(
      pages: [
        _page(['番茄炒蛋', '食材', '番茄 2个', '步骤', '番茄切�'], confidence: 0.9),
      ],
    );
    expect(
      quality.assessDocument(riskyButStructured).level,
      OcrTextQualityLevel.needsAttention,
    );
    expect(
      const LocalRecipeStructurerService()
          .structure(
            text: riskyButStructured.plainText,
            source: const SourceSnapshot(originalText: ''),
            ocrDocument: riskyButStructured,
          )
          .ingredients
          .value,
      isNotEmpty,
    );
  });

  test('繁体分区仅用等价键匹配，草稿值和证据保持原字形', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(['傳統滷肉飯', '食材', '馬鈴薯 適量', '步驟', '將馬鈴薯放入鍋中'], confidence: 0.9),
      ],
    );

    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(draft.title.value, '傳統滷肉飯');
    expect(draft.ingredients.value, contains('馬鈴薯 適量'));
    expect(draft.steps.value, contains('將馬鈴薯放入鍋中'));
    expect(
      draft.ingredients.evidence.map((item) => item.excerpt),
      contains('馬鈴薯 適量'),
    );
  });

  test('建议只覆盖明确数字或菜谱词误识别，不把繁体和合法混排判错', () {
    const service = OcrCorrectionSuggestionService();
    final document = OcrDocumentEntity(
      pages: [
        _page([
          '盐 1O克',
          '食村',
          '水 30毫开',
          '馬鈴著 2個',
          '馬鈴薯 適量',
          'Mix 後靜置 10分钟',
        ], confidence: 0.8),
      ],
    );

    final suggestions = service.generate(document);

    expect(
      suggestions.map((item) => item.originalText),
      containsAll(['O', '食村', '毫开', '馬鈴著']),
    );
    expect(suggestions.any((item) => item.originalText == '馬鈴薯'), isFalse);
    expect(
      suggestions.any((item) => item.originalText.contains('Mix')),
      isFalse,
    );
  });

  test('整段繁简转换只在显式调用时产生预览文本', () {
    const converter = OcrScriptConversionService();

    expect(converter.toSimplified('馬鈴薯燉雞'), '马铃薯炖鸡');
    expect(converter.toTraditional('马铃薯炖鸡'), '馬鈴薯燉鷄');
  });
}

OcrPageEntity _page(List<String> lines, {required double confidence}) {
  return OcrPageEntity(
    pageIndex: 0,
    pixelWidth: 1000,
    pixelHeight: 1600,
    lines: [
      for (final (index, text) in lines.indexed)
        OcrLineEntity(
          id: 'line-$index',
          text: text,
          confidence: confidence,
          boundingBox: OcrRectValueObject(
            left: 0.1,
            top: index / lines.length,
            right: 0.9,
            bottom: (index + 0.7) / lines.length,
          ),
        ),
    ],
  );
}
