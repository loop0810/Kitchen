enum CreateRecipeValidationField { title, category, template }

class CreateRecipeValidationFailure implements Exception {
  CreateRecipeValidationFailure(Map<CreateRecipeValidationField, String> errors)
    : assert(errors.isNotEmpty),
      errors = Map.unmodifiable(errors);

  final Map<CreateRecipeValidationField, String> errors;

  String get firstError => errors.values.first;

  String? errorFor(CreateRecipeValidationField field) => errors[field];

  @override
  String toString() => 'CreateRecipeValidationFailure($errors)';
}
