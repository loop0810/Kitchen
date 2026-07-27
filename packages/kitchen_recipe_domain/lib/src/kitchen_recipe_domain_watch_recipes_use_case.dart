import 'kitchen_recipe_domain_recipe_entity.dart';
import 'kitchen_recipe_domain_recipe_query.dart';
import 'kitchen_recipe_domain_recipe_repository.dart';

class WatchRecipesUseCase {
  const WatchRecipesUseCase(this._repository);

  final RecipeRepository _repository;

  Stream<List<RecipeEntity>> call(RecipeQuery query) {
    return _repository.watchRecipes(query);
  }
}
