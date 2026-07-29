import 'kitchen_recipe_domain_create_recipe_input.dart';
import 'kitchen_recipe_domain_create_recipe_validation_service.dart';
import 'kitchen_recipe_domain_recipe_repository.dart';

class CreateRecipeUseCase {
  const CreateRecipeUseCase(
    this._repository, {
    this.validationService = const CreateRecipeValidationService(),
  });

  final RecipeRepository _repository;
  final CreateRecipeValidationService validationService;

  Future<String> call(CreateRecipeInput input) {
    final failure = validationService(input);
    if (failure != null) throw failure;
    return _repository.createRecipe(input);
  }
}
