import 'kitchen_recipe_domain_create_recipe_input.dart';
import 'kitchen_recipe_domain_recipe_detail_entity.dart';
import 'kitchen_recipe_domain_recipe_entity.dart';
import 'kitchen_recipe_domain_recipe_query.dart';

abstract interface class RecipeRepository {
  Stream<List<RecipeEntity>> watchRecipes(RecipeQuery query);

  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId);

  Future<String> createRecipe(CreateRecipeInput input);

  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  });
}
