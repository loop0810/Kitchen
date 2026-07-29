import 'kitchen_recipe_template_rect_value_object.dart';
import 'kitchen_recipe_template_text_style_value_object.dart';

enum TemplateSlotKind {
  recipeTitle,
  primaryIngredients,
  detailAction,
  category,
  totalTime,
}

enum TemplateOverflowRule { ellipsis, clip }

enum TemplateContentAlignment {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class TemplateSlot {
  const TemplateSlot({
    required this.kind,
    required this.rect,
    required this.alignment,
    required this.textStyle,
    required this.maxLines,
    required this.overflowRule,
    required this.visibleInThumbnail,
    required this.accessibilityLabel,
  });

  final TemplateSlotKind kind;
  final TemplateRectValueObject rect;
  final TemplateContentAlignment alignment;
  final TemplateTextStyleValueObject textStyle;
  final int maxLines;
  final TemplateOverflowRule overflowRule;
  final bool visibleInThumbnail;
  final String accessibilityLabel;
}
