import 'kitchen_recipe_domain_ingredient_entity.dart';
import 'kitchen_recipe_domain_ingredient_group_entity.dart';
import 'kitchen_recipe_domain_recipe_entity.dart';
import 'kitchen_recipe_domain_recipe_step_entity.dart';

class RecipeDetailEntity {
  const RecipeDetailEntity({
    required this.recipe,
    required this.groups,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });

  final RecipeEntity recipe;
  final List<IngredientGroupEntity> groups;
  final List<IngredientEntity> ingredients;
  final List<RecipeStepEntity> steps;
  final List<String> tags;
}
