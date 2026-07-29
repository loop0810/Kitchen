class RecipeTemplateSelectionValueObject {
  const RecipeTemplateSelectionValueObject({
    required this.templateId,
    required this.templateVersion,
  });

  final String templateId;
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
