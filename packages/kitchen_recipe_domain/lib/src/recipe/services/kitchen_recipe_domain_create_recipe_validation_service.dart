import '../inputs/kitchen_recipe_domain_create_recipe_input.dart';
import '../failures/kitchen_recipe_domain_create_recipe_validation_failure.dart';

class CreateRecipeValidationService {
  const CreateRecipeValidationService();

  CreateRecipeValidationFailure? call(CreateRecipeInput input) {
    // 一次收集全部字段错误，便于 UI 同时标记多个输入框。
    final errors = <CreateRecipeValidationField, String>{};
    final title = input.title.trim();
    if (title.isEmpty) {
      errors[CreateRecipeValidationField.title] = '请输入菜名';
    } else if (title.length > 120) {
      errors[CreateRecipeValidationField.title] = '菜名不能超过 120 个字符';
    }
    if (input.category.trim().isEmpty) {
      errors[CreateRecipeValidationField.category] = '请选择主分类';
    }
    if (input.templateSelection.templateId.trim().isEmpty ||
        input.templateSelection.templateVersion <= 0) {
      errors[CreateRecipeValidationField.template] = '请选择可用的手账模板';
    }

    return errors.isEmpty ? null : CreateRecipeValidationFailure(errors);
  }
}
