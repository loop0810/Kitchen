import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

void main() {
  test('内置基础模板通过校验并可按稳定版本解析', () {
    const validator = TemplateValidatorService();
    final catalog = BuiltInTemplates.createCatalog();

    expect(validator(BuiltInTemplates.basicJournal), isEmpty);
    expect(
      catalog.find(id: 'builtin.journal.basic', version: 1),
      same(BuiltInTemplates.basicJournal),
    );
  });

  test('模板缺少必要槽位或坐标越界时校验失败', () {
    const validator = TemplateValidatorService();
    final definition = _definition(
      slots: const [
        TemplateSlot(
          kind: TemplateSlotKind.recipeTitle,
          rect: TemplateRectValueObject(
            left: 0.8,
            top: 0,
            width: 0.4,
            height: 0.2,
          ),
          alignment: TemplateContentAlignment.topLeft,
          textStyle: TemplateTextStyleValueObject(
            fontSize: 20,
            fontWeight: 700,
            colorValue: 0xFF000000,
          ),
          maxLines: 1,
          overflowRule: TemplateOverflowRule.ellipsis,
          visibleInThumbnail: true,
          accessibilityLabel: '菜名',
        ),
      ],
    );

    final codes = validator(definition).map((failure) => failure.code);

    expect(codes, contains(TemplateValidationFailureCode.invalidRect));
    expect(codes, contains(TemplateValidationFailureCode.missingRequiredSlot));
  });

  test('请求不存在的模板时解析器返回内置默认模板', () {
    final resolver = TemplateResolverService(
      catalog: BuiltInTemplates.createCatalog(),
      defaultSelection: BuiltInTemplates.defaultSelection,
    );

    final result = resolver(
      const RecipeTemplateSelectionValueObject(
        templateId: 'missing.template',
        templateVersion: 99,
      ),
    );

    expect(result.definition, same(BuiltInTemplates.basicJournal));
    expect(result.usedFallback, isTrue);
    expect(result.fallbackReason, TemplateFallbackReason.missingTemplate);
  });

  test('模板最低版本高于当前 App 时降级到默认模板', () {
    final futureTemplate = _definition(
      id: 'future.template',
      minimumAppVersion: '2.0.0',
      slots: BuiltInTemplates.basicJournal.slots,
    );
    final catalog = TemplateCatalog(
      definitions: [BuiltInTemplates.basicJournal, futureTemplate],
    );
    final resolver = TemplateResolverService(
      catalog: catalog,
      defaultSelection: BuiltInTemplates.defaultSelection,
    );

    final result = resolver(
      const RecipeTemplateSelectionValueObject(
        templateId: 'future.template',
        templateVersion: 1,
      ),
    );

    expect(result.definition, same(BuiltInTemplates.basicJournal));
    expect(
      result.fallbackReason,
      TemplateFallbackReason.incompatibleAppVersion,
    );
  });
}

TemplateDefinition _definition({
  String id = 'test.template',
  String minimumAppVersion = '1.0.0',
  required List<TemplateSlot> slots,
}) {
  return TemplateDefinition(
    id: id,
    version: 1,
    name: '测试模板',
    author: '测试',
    aspectRatio: 2 / 3,
    designWidth: 300,
    canvasColorValue: 0xFFFFFFFF,
    slots: slots,
    decorationLayers: const [],
    bundledFonts: const [],
    minimumAppVersion: minimumAppVersion,
    entitlementType: TemplateEntitlementType.bundledFree,
  );
}
