import 'kitchen_recipe_domain_create_recipe_input.dart';
import 'kitchen_recipe_domain_recipe_repository.dart';

class CreateRecipeUseCase {
  const CreateRecipeUseCase(this._repository);

  final RecipeRepository _repository;

  Future<String> call(CreateRecipeInput input) {
    return _repository.createRecipe(input);
  }
}
