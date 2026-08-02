class TemplateRectValueObject {
  const TemplateRectValueObject({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// 矩形左边缘相对画布宽度的比例，取值范围为 0～1。
  final double left;

  /// 矩形上边缘相对画布高度的比例，取值范围为 0～1。
  final double top;

  /// 矩形宽度相对画布宽度的比例，取值范围为 0～1。
  final double width;

  /// 矩形高度相对画布高度的比例，取值范围为 0～1。
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
