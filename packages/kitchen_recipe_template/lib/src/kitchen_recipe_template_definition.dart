import 'kitchen_recipe_template_decoration_layer.dart';
import 'kitchen_recipe_template_slot.dart';

enum TemplateEntitlementType { bundledFree, purchased }

class TemplateDefinition {
  const TemplateDefinition({
    required this.id,
    required this.version,
    required this.name,
    required this.author,
    required this.aspectRatio,
    required this.designWidth,
    required this.canvasColorValue,
    required this.slots,
    required this.decorationLayers,
    required this.bundledFonts,
    required this.minimumAppVersion,
    required this.entitlementType,
    this.previewAsset,
    this.backgroundAsset,
  });

  final String id;
  final int version;
  final String name;
  final String author;
  final double aspectRatio;
  final double designWidth;
  final int canvasColorValue;
  final String? previewAsset;
  final String? backgroundAsset;
  final List<TemplateSlot> slots;
  final List<TemplateDecorationLayer> decorationLayers;
  final List<String> bundledFonts;
  final String minimumAppVersion;
  final TemplateEntitlementType entitlementType;
}
