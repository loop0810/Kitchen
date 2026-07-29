import 'kitchen_recipe_domain_create_recipe_input.dart';
import 'kitchen_recipe_domain_create_recipe_validation_service.dart';
import 'kitchen_recipe_domain_recipe_repository.dart';
import 'kitchen_recipe_domain_update_recipe_input.dart';

class UpdateRecipeUseCase {
  const UpdateRecipeUseCase(
    this._repository, {
    this.validationService = const CreateRecipeValidationService(),
  });

  final RecipeRepository _repository;
  final CreateRecipeValidationService validationService;

  Future<void> call(UpdateRecipeInput input) {
    // 更新与创建共用同一组用户可见字段规则，避免两个入口产生不同的合法数据。
    final failure = validationService(
      CreateRecipeInput(
        title: input.title,
        summary: input.summary,
        category: input.category,
        ingredients: input.ingredients
            .map((ingredient) => ingredient.name)
            .toList(growable: false),
        steps: input.steps
            .map((step) => step.instruction)
            .toList(growable: false),
        templateSelection: input.templateSelection,
      ),
    );
    if (failure != null) throw failure;
    return _repository.updateRecipe(input);
  }
}
