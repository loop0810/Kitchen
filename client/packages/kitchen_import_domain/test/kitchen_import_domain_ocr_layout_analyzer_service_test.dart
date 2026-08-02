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

  test('同排食材与步骤标题按左右区域读取且忽略下方平台正文', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('title', '清炒四季豆', 0.18, 0.14, 0.80, 0.20),
          _line('ingredient-heading', '食材准备', 0.10, 0.25, 0.34, 0.28),
          _line('step-heading', '做法步骤', 0.57, 0.25, 0.83, 0.28),
          _line('ingredient-1', '四季豆300g', 0.18, 0.32, 0.38, 0.35),
          _line('step-1', '① 四季豆洗净切段', 0.50, 0.31, 0.82, 0.34),
          _line('ingredient-2', '蒜末适量', 0.18, 0.41, 0.34, 0.44),
          _line('step-2', '② 热锅下油，爆香蒜末', 0.50, 0.40, 0.91, 0.43),
          _line('ingredient-3', '干辣椒3个', 0.18, 0.50, 0.37, 0.53),
          _line('step-3', '③ 倒入四季豆大火翻炒', 0.50, 0.49, 0.91, 0.52),
          _line('tip', '小贴士：大火快炒更脆嫩', 0.25, 0.67, 0.72, 0.70),
          _line('promotion', '管理期不挨饿！这些好吃素菜收好', 0.04, 0.76, 0.88, 0.79),
        ]),
      ],
    );

    final analysis = const OcrLayoutAnalyzerService().analyze(document);
    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(analysis.normalizedText, contains('食材\n四季豆300g\n蒜末适量\n干辣椒3个'));
    expect(analysis.normalizedText, contains('步骤\n① 四季豆洗净切段'));
    expect(analysis.normalizedText, isNot(contains('管理期不挨饿')));
    expect(draft.title.value, '清炒四季豆');
    expect(draft.ingredients.value, ['四季豆 300g', '蒜末 适量', '干辣椒 3个']);
    expect(draft.steps.value, ['四季豆洗净切段', '热锅下油，爆香蒜末', '倒入四季豆大火翻炒']);
  });

  test('横向食材卡片按横坐标配对下一行用量', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('title', '菌菇芦笋炒虾', 0.17, 0.12, 0.90, 0.20),
          _line('ingredient-heading', '食材清单（1人份）', 0.07, 0.42, 0.32, 0.44),
          _line('name-1', '芦笋', 0.07, 0.48, 0.14, 0.50),
          _line('name-2', '虾仁', 0.18, 0.48, 0.25, 0.50),
          _line('name-3', '菌菇', 0.30, 0.48, 0.37, 0.50),
          _line('amount-1', '1 50g', 0.07, 0.51, 0.15, 0.53),
          _line('amount-2', '1 20g', 0.18, 0.51, 0.26, 0.53),
          _line('amount-3', '120g', 0.30, 0.51, 0.38, 0.53),
          _line('step-heading', '制作步骤', 0.06, 0.56, 0.21, 0.58),
          _line('step-1', '1 芦笋切段，虾仁去虾线', 0.06, 0.60, 0.27, 0.63),
          _line('timer', 'Q3分钟', 0.06, 0.65, 0.14, 0.67),
        ]),
      ],
    );

    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(draft.ingredients.value, ['芦笋 150g', '虾仁 120g', '菌菇 120g']);
    expect(draft.steps.value, ['芦笋切段，虾仁去虾线']);
  });

  test('三栏两排步骤卡片按面板而非同一横线拼接', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('title', '红烧豆腐', 0.06, 0.20, 0.47, 0.26),
          _line('step-heading', '制作步骤', 0.04, 0.47, 0.20, 0.49),
          _line('p1-a', '豆腐切块，平底锅热油，', 0.04, 0.59, 0.31, 0.61),
          _line('p1-b', '煎至两面金黄，盛出备用。', 0.04, 0.61, 0.31, 0.64),
          _line('p2-a', '锅中留底油，放蒜末炒香，', 0.36, 0.59, 0.64, 0.61),
          _line('p2-b', '加入豆瓣酱炒出红油。', 0.36, 0.61, 0.64, 0.64),
          _line('p3-a', '倒入煎好的豆腐，加入生抽。', 0.68, 0.59, 0.96, 0.61),
          _line('p3-b', '轻轻翻炒均匀。', 0.68, 0.61, 0.89, 0.64),
          _line('p4-a', '倒入半碗清水，中小火焖煮。', 0.04, 0.74, 0.31, 0.76),
          _line('p5-a', '开盖收汁，淋入水淀粉。', 0.36, 0.74, 0.64, 0.76),
          _line('p6-a', '撒上葱花，翻匀即可出锅。', 0.68, 0.74, 0.96, 0.76),
        ]),
      ],
    );

    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(draft.steps.value, [
      '豆腐切块，平底锅热油，煎至两面金黄，盛出备用。',
      '锅中留底油，放蒜末炒香，加入豆瓣酱炒出红油。',
      '倒入煎好的豆腐，加入生抽。轻轻翻炒均匀。',
      '倒入半碗清水，中小火焖煮。',
      '开盖收汁，淋入水淀粉。',
      '撒上葱花，翻匀即可出锅。',
    ]);
  });

  test('同页重复出现完整食材和步骤分区时提示可能包含多道菜', () {
    final document = OcrDocumentEntity(
      pages: [
        _page(0, [
          _line('title-1', '清炒西兰花', 0.05, 0.08, 0.40, 0.12),
          _line('ingredient-1', '食材', 0.05, 0.14, 0.20, 0.17),
          _line('broccoli', '西兰花300g', 0.05, 0.19, 0.30, 0.22),
          _line('step-1', '步骤', 0.05, 0.25, 0.20, 0.28),
          _line('cook-1', '1 西兰花焯水后翻炒', 0.05, 0.30, 0.50, 0.33),
          _line('title-2', '蒜蓉菠菜', 0.05, 0.52, 0.40, 0.56),
          _line('ingredient-2', '食材', 0.05, 0.58, 0.20, 0.61),
          _line('spinach', '菠菜300g', 0.05, 0.63, 0.30, 0.66),
          _line('step-2', '步骤', 0.05, 0.69, 0.20, 0.72),
          _line('cook-2', '1 菠菜焯水后翻炒', 0.05, 0.74, 0.50, 0.77),
        ]),
      ],
    );

    final analysis = const OcrLayoutAnalyzerService().analyze(document);
    final draft = const LocalRecipeStructurerService().structure(
      text: document.plainText,
      source: const SourceSnapshot(originalText: ''),
      ocrDocument: document,
    );

    expect(analysis.possibleMultipleRecipes, isTrue);
    expect(draft.warnings, contains(contains('可能包含多道菜')));
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
