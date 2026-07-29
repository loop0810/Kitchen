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

  /// 该槽位承载的业务内容类型。
  final TemplateSlotKind kind;

  /// 槽位在标准化画布中的位置和大小。
  final TemplateRectValueObject rect;

  /// 内容在槽位矩形内部的对齐方式。
  final TemplateContentAlignment alignment;

  /// 槽位文字的字号、字重、颜色和文本对齐方式。
  final TemplateTextStyleValueObject textStyle;

  /// 槽位允许展示的最大文本行数。
  final int maxLines;

  /// 内容超过槽位容量时采用的截断规则。
  final TemplateOverflowRule overflowRule;

  /// 该槽位是否需要出现在列表缩略图中。
  final bool visibleInThumbnail;

  /// 辅助功能中用于说明该槽位用途的语义标签。
  final String accessibilityLabel;
}
