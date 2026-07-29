enum CreateRecipeValidationField { title, category, template }

class CreateRecipeValidationFailure implements Exception {
  CreateRecipeValidationFailure(Map<CreateRecipeValidationField, String> errors)
    : assert(errors.isNotEmpty),
      errors = Map.unmodifiable(errors);

  /// 按字段保存的错误文案；一个校验结果可以同时包含多个字段错误。
  final Map<CreateRecipeValidationField, String> errors;

  String get firstError => errors.values.first;

  String? errorFor(CreateRecipeValidationField field) => errors[field];

  @override
  String toString() => 'CreateRecipeValidationFailure($errors)';
}
