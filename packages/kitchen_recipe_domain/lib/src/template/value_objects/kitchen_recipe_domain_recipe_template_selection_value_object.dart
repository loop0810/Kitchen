class RecipeTemplateSelectionValueObject {
  const RecipeTemplateSelectionValueObject({
    required this.templateId,
    required this.templateVersion,
  });

  /// 模板的稳定标识。
  final String templateId;

  /// 被选中模板的固定版本号，用于复现保存时的版式。
  final int templateVersion;

  @override
  bool operator ==(Object other) {
    return other is RecipeTemplateSelectionValueObject &&
        other.templateId == templateId &&
        other.templateVersion == templateVersion;
  }

  @override
  int get hashCode => Object.hash(templateId, templateVersion);
}
