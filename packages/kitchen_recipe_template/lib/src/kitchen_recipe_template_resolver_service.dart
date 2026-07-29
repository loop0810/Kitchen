import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_template_app_version_value_object.dart';
import 'kitchen_recipe_template_catalog.dart';
import 'kitchen_recipe_template_definition.dart';
import 'kitchen_recipe_template_resolution.dart';

class TemplateResolverService {
  const TemplateResolverService({
    required this.catalog,
    required this.defaultSelection,
    this.currentAppVersion = const TemplateAppVersionValueObject(
      major: 1,
      minor: 0,
      patch: 0,
    ),
  });

  final TemplateCatalog catalog;
  final RecipeTemplateSelectionValueObject defaultSelection;
  final TemplateAppVersionValueObject currentAppVersion;

  TemplateResolution call(RecipeTemplateSelectionValueObject selection) {
    // 菜谱保存模板 ID + 版本，确保模板升级后仍能复现当时选择的版式。
    final requested = catalog.find(
      id: selection.templateId,
      version: selection.templateVersion,
    );
    if (requested != null && _isCompatible(requested)) {
      return TemplateResolution(definition: requested, usedFallback: false);
    }

    // 模板被移除或需要更高 App 版本时回退到内置模板，菜谱内容仍可离线阅读。
    final fallback = catalog.find(
      id: defaultSelection.templateId,
      version: defaultSelection.templateVersion,
    );
    if (fallback == null || !_isCompatible(fallback)) {
      throw StateError('内置默认模板不存在或与当前 App 版本不兼容。');
    }
    return TemplateResolution(
      definition: fallback,
      usedFallback: true,
      fallbackReason: requested == null
          ? TemplateFallbackReason.missingTemplate
          : TemplateFallbackReason.incompatibleAppVersion,
    );
  }

  bool _isCompatible(TemplateDefinition definition) {
    final minimumVersion = TemplateAppVersionValueObject.tryParse(
      definition.minimumAppVersion,
    );
    return minimumVersion != null &&
        currentAppVersion.compareTo(minimumVersion) >= 0;
  }
}
