class TemplateRectValueObject {
  const TemplateRectValueObject({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  bool get isNormalized {
    return left >= 0 &&
        top >= 0 &&
        width > 0 &&
        height > 0 &&
        left + width <= 1 &&
        top + height <= 1;
  }
}
