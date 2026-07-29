import 'kitchen_recipe_template_rect_value_object.dart';

class TemplateDecorationLayer {
  const TemplateDecorationLayer({
    required this.rect,
    required this.colorValue,
    this.borderRadius = 0,
    this.rotationDegrees = 0,
    this.visibleInThumbnail = true,
  });

  final TemplateRectValueObject rect;
  final int colorValue;
  final double borderRadius;
  final double rotationDegrees;
  final bool visibleInThumbnail;
}
