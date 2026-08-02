import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_template_catalog.dart';
import '../models/kitchen_recipe_template_decoration_layer.dart';
import '../models/kitchen_recipe_template_definition.dart';
import '../value_objects/kitchen_recipe_template_rect_value_object.dart';
import '../services/kitchen_recipe_template_resolver_service.dart';
import '../models/kitchen_recipe_template_slot.dart';
import '../value_objects/kitchen_recipe_template_text_style_value_object.dart';

abstract final class BuiltInTemplates {
  static const defaultSelection = RecipeTemplateSelectionValueObject(
    templateId: 'builtin.journal.basic',
    templateVersion: 1,
  );

  static const basicJournal = TemplateDefinition(
    id: 'builtin.journal.basic',
    version: 1,
    name: '基础手账',
    author: '厨房手记',
    aspectRatio: 2 / 3,
    designWidth: 300,
    canvasColorValue: 0xFFFFFDF8,
    slots: [
      TemplateSlot(
        kind: TemplateSlotKind.recipeTitle,
        rect: TemplateRectValueObject(
          left: 0.11,
          top: 0.1,
          width: 0.78,
          height: 0.18,
        ),
        alignment: TemplateContentAlignment.centerLeft,
        textStyle: TemplateTextStyleValueObject(
          fontSize: 28,
          fontWeight: 700,
          colorValue: 0xFF403B37,
        ),
        maxLines: 2,
        overflowRule: TemplateOverflowRule.ellipsis,
        visibleInThumbnail: true,
        accessibilityLabel: '菜名',
      ),
      TemplateSlot(
        kind: TemplateSlotKind.primaryIngredients,
        rect: TemplateRectValueObject(
          left: 0.11,
          top: 0.34,
          width: 0.78,
          height: 0.42,
        ),
        alignment: TemplateContentAlignment.topLeft,
        textStyle: TemplateTextStyleValueObject(
          fontSize: 16,
          fontWeight: 500,
          colorValue: 0xFF403B37,
        ),
        maxLines: 4,
        overflowRule: TemplateOverflowRule.ellipsis,
        visibleInThumbnail: true,
        accessibilityLabel: '主要食材',
      ),
      TemplateSlot(
        kind: TemplateSlotKind.detailAction,
        rect: TemplateRectValueObject(
          left: 0.55,
          top: 0.84,
          width: 0.34,
          height: 0.07,
        ),
        alignment: TemplateContentAlignment.centerRight,
        textStyle: TemplateTextStyleValueObject(
          fontSize: 12,
          fontWeight: 600,
          colorValue: 0xFFD96B58,
          alignment: TemplateTextAlignment.end,
        ),
        maxLines: 1,
        overflowRule: TemplateOverflowRule.clip,
        visibleInThumbnail: false,
        accessibilityLabel: '查看详情',
      ),
    ],
    decorationLayers: [
      TemplateDecorationLayer(
        rect: TemplateRectValueObject(
          left: 0.27,
          top: 0.025,
          width: 0.46,
          height: 0.055,
        ),
        colorValue: 0xFFF4DFA7,
        borderRadius: 2,
        rotationDegrees: -1.2,
      ),
      TemplateDecorationLayer(
        rect: TemplateRectValueObject(
          left: 0.075,
          top: 0.31,
          width: 0.025,
          height: 0.45,
        ),
        colorValue: 0xFFA9B9A2,
        borderRadius: 4,
      ),
      TemplateDecorationLayer(
        rect: TemplateRectValueObject(
          left: 0.1,
          top: 0.79,
          width: 0.8,
          height: 0.004,
        ),
        colorValue: 0xFFF5DDD5,
      ),
    ],
    bundledFonts: [],
    minimumAppVersion: '1.0.0',
    entitlementType: TemplateEntitlementType.bundledFree,
  );

  static TemplateCatalog createCatalog() {
    return TemplateCatalog(definitions: const [basicJournal]);
  }

  static final defaultCatalog = createCatalog();

  static final defaultResolver = TemplateResolverService(
    catalog: defaultCatalog,
    defaultSelection: defaultSelection,
  );
}
