enum TemplateTextAlignment { start, center, end }

class TemplateTextStyleValueObject {
  const TemplateTextStyleValueObject({
    required this.fontSize,
    required this.fontWeight,
    required this.colorValue,
    this.alignment = TemplateTextAlignment.start,
  });

  /// 基于模板设计宽度定义的字号。
  final double fontSize;

  /// CSS 风格的数字字重，合法范围为 100～900。
  final int fontWeight;

  /// 文字使用的 ARGB 颜色整数。
  final int colorValue;

  /// 文字在自身可用宽度内的水平对齐方式。
  final TemplateTextAlignment alignment;
}
