import '../../ingredient/value_objects/kitchen_recipe_domain_ingredient_summary_value_object.dart';
import 'kitchen_recipe_domain_recipe_entity.dart';

class RecipeJournalSummaryEntity {
  const RecipeJournalSummaryEntity({
    required this.recipe,
    required this.primaryIngredients,
  });

  /// 摘要对应的菜谱基础信息。
  final RecipeEntity recipe;

  /// 手账缩略图优先展示的食材，数量通常不超过四项。
  final List<IngredientSummaryValueObject> primaryIngredients;
}
