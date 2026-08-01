import '../entities/kitchen_recipe_domain_recipe_detail_entity.dart';
import '../repositories/kitchen_recipe_domain_recipe_repository.dart';

class GetRecipeDetailUseCase {
  const GetRecipeDetailUseCase(this._repository);

  final RecipeRepository _repository;

  Future<RecipeDetailEntity?> call(String recipeId) {
    return _repository.getRecipeDetail(recipeId);
  }
}
