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

  /// 模板跨版本保持不变的稳定标识。
  final String id;

  /// 模板结构版本，用于准确复现菜谱保存时的版式。
  final int version;

  /// 面向用户展示的模板名称。
  final String name;

  /// 模板作者或提供方名称。
  final String author;

  /// 画布宽度与高度的比例。
  final double aspectRatio;

  /// 设计稿基准宽度，渲染器以此计算字体和圆角缩放比例。
  final double designWidth;

  /// 模板画布背景的 ARGB 颜色整数。
  final int canvasColorValue;

  /// 模板商城或选择页使用的可选预览资源路径。
  final String? previewAsset;

  /// 铺在画布底部的可选背景资源路径。
  final String? backgroundAsset;

  /// 承载菜谱动态内容的槽位定义。
  final List<TemplateSlot> slots;

  /// 不承载业务内容的静态装饰图层。
  final List<TemplateDecorationLayer> decorationLayers;

  /// 模板离线渲染所需、随资源包提供的字体名称。
  final List<String> bundledFonts;

  /// 能够安全渲染本模板的最低 App 版本，格式为 `major.minor.patch`。
  final String minimumAppVersion;

  /// 用户获得该模板的权益类型。
  final TemplateEntitlementType entitlementType;
}
