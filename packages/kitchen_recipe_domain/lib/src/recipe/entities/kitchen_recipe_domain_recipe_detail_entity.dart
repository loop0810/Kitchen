import '../../ingredient/entities/kitchen_recipe_domain_ingredient_entity.dart';
import 'kitchen_recipe_domain_recipe_entity.dart';
import 'kitchen_recipe_domain_recipe_step_entity.dart';

class RecipeDetailEntity {
  const RecipeDetailEntity({
    required this.recipe,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });

  /// 菜谱的基础信息。
  final RecipeEntity recipe;

  /// 按展示顺序排列的全部食材。
  final List<IngredientEntity> ingredients;

  /// 按执行顺序排列的全部烹饪步骤。
  final List<RecipeStepEntity> steps;

  /// 用户为菜谱添加的标签名称。
  final List<String> tags;
}
