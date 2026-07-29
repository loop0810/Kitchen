enum TemplateTextAlignment { start, center, end }

class TemplateTextStyleValueObject {
  const TemplateTextStyleValueObject({
    required this.fontSize,
    required this.fontWeight,
    required this.colorValue,
    this.alignment = TemplateTextAlignment.start,
  });

  final double fontSize;
  final int fontWeight;
  final int colorValue;
  final TemplateTextAlignment alignment;
}
