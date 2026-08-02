import '../models/kitchen_recipe_template_definition.dart';

enum TemplateFallbackReason { missingTemplate, incompatibleAppVersion }

class TemplateResolution {
  const TemplateResolution({
    required this.definition,
    required this.usedFallback,
    this.fallbackReason,
  });

  /// 最终实际用于渲染的模板定义，可能是请求模板或内置回退模板。
  final TemplateDefinition definition;

  /// 最终结果是否使用了回退模板。
  final bool usedFallback;

  /// 发生回退的原因；未回退时为空。
  final TemplateFallbackReason? fallbackReason;
}
