import '../value_objects/kitchen_recipe_template_rect_value_object.dart';

class TemplateDecorationLayer {
  const TemplateDecorationLayer({
    required this.rect,
    required this.colorValue,
    this.borderRadius = 0,
    this.rotationDegrees = 0,
    this.visibleInThumbnail = true,
  });

  /// 装饰层在标准化画布中的位置和大小。
  final TemplateRectValueObject rect;

  /// 装饰层填充使用的 ARGB 颜色整数。
  final int colorValue;

  /// 基于模板设计宽度定义的圆角半径。
  final double borderRadius;

  /// 围绕装饰层中心旋转的角度值。
  final double rotationDegrees;

  /// 该装饰层是否需要出现在列表缩略图中。
  final bool visibleInThumbnail;
}
