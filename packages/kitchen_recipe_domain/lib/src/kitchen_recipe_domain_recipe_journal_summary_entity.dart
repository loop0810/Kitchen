import 'kitchen_recipe_domain_ingredient_summary_value_object.dart';
import 'kitchen_recipe_domain_recipe_entity.dart';

class RecipeJournalSummaryEntity {
  const RecipeJournalSummaryEntity({
    required this.recipe,
    required this.primaryIngredients,
  });

  final RecipeEntity recipe;
  final List<IngredientSummaryValueObject> primaryIngredients;
}
