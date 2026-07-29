import 'kitchen_recipe_template_definition.dart';

enum TemplateFallbackReason { missingTemplate, incompatibleAppVersion }

class TemplateResolution {
  const TemplateResolution({
    required this.definition,
    required this.usedFallback,
    this.fallbackReason,
  });

  final TemplateDefinition definition;
  final bool usedFallback;
  final TemplateFallbackReason? fallbackReason;
}
