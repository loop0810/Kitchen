import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

void main() {
  const validator = TemplateValidatorService();

  test('完整模板通过校验且不返回任何失败', () {
    expect(validator(_definition()), isEmpty);
  });

  test('校验结果不可修改，避免调用方污染诊断列表', () {
    final failures = validator(_definition(id: '  '));

    expect(
      () => failures.add(
        const TemplateValidationFailure(
          code: TemplateValidationFailureCode.missingId,
          message: 'x',
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('模板 ID 只有空白时报告缺少 ID', () {
    expect(
      _codes(validator(_definition(id: '   '))),
      contains(TemplateValidationFailureCode.missingId),
    );
  });

  test('版本号非正数时报告版本无效', () {
    expect(
      _codes(validator(_definition(version: 0))),
      contains(TemplateValidationFailureCode.invalidVersion),
    );
  });

  test('画布比例为非正数或非有限值时报告比例无效', () {
    expect(
      _codes(validator(_definition(aspectRatio: 0))),
      contains(TemplateValidationFailureCode.invalidAspectRatio),
    );
    expect(
      _codes(validator(_definition(aspectRatio: double.nan))),
      contains(TemplateValidationFailureCode.invalidAspectRatio),
    );
  });

  test('设计宽度为非正数或非有限值时报告宽度无效', () {
    expect(
      _codes(validator(_definition(designWidth: -1))),
      contains(TemplateValidationFailureCode.invalidDesignWidth),
    );
    expect(
      _codes(validator(_definition(designWidth: double.infinity))),
      contains(TemplateValidationFailureCode.invalidDesignWidth),
    );
  });

  test('最低 App 版本不是 major.minor.patch 时报告版本格式无效', () {
    expect(
      _codes(validator(_definition(minimumAppVersion: '1.0'))),
      contains(TemplateValidationFailureCode.invalidMinimumAppVersion),
    );
  });

  test('槽位最大行数非正数时报告行数无效并保留槽位名称', () {
    final failures = validator(
      _definition(
        slots: [
          _slot(TemplateSlotKind.recipeTitle, maxLines: 0),
          _slot(TemplateSlotKind.primaryIngredients),
          _slot(TemplateSlotKind.detailAction),
        ],
      ),
    );

    expect(
      _codes(failures),
      contains(TemplateValidationFailureCode.invalidMaxLines),
    );
    expect(failures.single.message, contains('recipeTitle'));
  });

  test('槽位字号或字重越界时报告文字样式无效', () {
    for (final style in const [
      TemplateTextStyleValueObject(
        fontSize: 0,
        fontWeight: 400,
        colorValue: 0xFF000000,
      ),
      TemplateTextStyleValueObject(
        fontSize: 16,
        fontWeight: 99,
        colorValue: 0xFF000000,
      ),
      TemplateTextStyleValueObject(
        fontSize: 16,
        fontWeight: 901,
        colorValue: 0xFF000000,
      ),
    ]) {
      final failures = validator(
        _definition(
          slots: [
            _slot(TemplateSlotKind.recipeTitle, textStyle: style),
            _slot(TemplateSlotKind.primaryIngredients),
            _slot(TemplateSlotKind.detailAction),
          ],
        ),
      );

      expect(
        _codes(failures),
        contains(TemplateValidationFailureCode.invalidTextStyle),
        reason: '${style.fontSize}/${style.fontWeight}',
      );
    }
  });

  test('同类槽位重复时报告重复槽位', () {
    final failures = validator(
      _definition(
        slots: [
          _slot(TemplateSlotKind.recipeTitle),
          _slot(TemplateSlotKind.recipeTitle),
          _slot(TemplateSlotKind.primaryIngredients),
          _slot(TemplateSlotKind.detailAction),
        ],
      ),
    );

    expect(
      _codes(failures),
      contains(TemplateValidationFailureCode.duplicateSlot),
    );
  });

  test('装饰层坐标越界时报告坐标无效', () {
    final failures = validator(
      _definition(
        decorationLayers: const [
          TemplateDecorationLayer(
            rect: TemplateRectValueObject(
              left: 0.6,
              top: 0,
              width: 0.5,
              height: 0.2,
            ),
            colorValue: 0xFF000000,
          ),
        ],
      ),
    );

    expect(
      _codes(failures),
      contains(TemplateValidationFailureCode.invalidRect),
    );
    expect(failures.single.message, contains('装饰层'));
  });

  test('缺少全部必需槽位时逐项报告缺失', () {
    final failures = validator(_definition(slots: const []));

    expect(
      _codes(failures),
      everyElement(TemplateValidationFailureCode.missingRequiredSlot),
    );
    expect(failures, hasLength(3));
    expect(
      failures.map((failure) => failure.message).join(),
      allOf(
        contains('recipeTitle'),
        contains('primaryIngredients'),
        contains('detailAction'),
      ),
    );
  });

  test('一次校验同时收集元数据和槽位的全部问题', () {
    final failures = validator(
      _definition(
        id: '',
        version: -1,
        aspectRatio: 0,
        designWidth: 0,
        minimumAppVersion: 'v1',
        slots: const [],
      ),
    );

    expect(
      _codes(failures),
      containsAll(const [
        TemplateValidationFailureCode.missingId,
        TemplateValidationFailureCode.invalidVersion,
        TemplateValidationFailureCode.invalidAspectRatio,
        TemplateValidationFailureCode.invalidDesignWidth,
        TemplateValidationFailureCode.invalidMinimumAppVersion,
        TemplateValidationFailureCode.missingRequiredSlot,
      ]),
    );
  });
}

Iterable<TemplateValidationFailureCode> _codes(
  List<TemplateValidationFailure> failures,
) {
  return failures.map((failure) => failure.code);
}

TemplateSlot _slot(
  TemplateSlotKind kind, {
  int maxLines = 1,
  TemplateRectValueObject rect = const TemplateRectValueObject(
    left: 0,
    top: 0,
    width: 0.5,
    height: 0.2,
  ),
  TemplateTextStyleValueObject textStyle = const TemplateTextStyleValueObject(
    fontSize: 16,
    fontWeight: 400,
    colorValue: 0xFF000000,
  ),
}) {
  return TemplateSlot(
    kind: kind,
    rect: rect,
    alignment: TemplateContentAlignment.topLeft,
    textStyle: textStyle,
    maxLines: maxLines,
    overflowRule: TemplateOverflowRule.ellipsis,
    visibleInThumbnail: true,
    accessibilityLabel: kind.name,
  );
}

TemplateDefinition _definition({
  String id = 'test.template',
  int version = 1,
  double aspectRatio = 2 / 3,
  double designWidth = 300,
  String minimumAppVersion = '1.0.0',
  List<TemplateSlot>? slots,
  List<TemplateDecorationLayer> decorationLayers = const [],
}) {
  return TemplateDefinition(
    id: id,
    version: version,
    name: '测试模板',
    author: '测试',
    aspectRatio: aspectRatio,
    designWidth: designWidth,
    canvasColorValue: 0xFFFFFFFF,
    slots:
        slots ??
        [
          _slot(TemplateSlotKind.recipeTitle),
          _slot(TemplateSlotKind.primaryIngredients),
          _slot(TemplateSlotKind.detailAction),
        ],
    decorationLayers: decorationLayers,
    bundledFonts: const [],
    minimumAppVersion: minimumAppVersion,
    entitlementType: TemplateEntitlementType.bundledFree,
  );
}
