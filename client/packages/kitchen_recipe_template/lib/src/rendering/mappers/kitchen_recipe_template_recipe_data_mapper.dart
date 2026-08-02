import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../models/kitchen_recipe_template_render_data.dart';

abstract final class RecipeTemplateDataMapper {
  static TemplateRenderData fromJournalSummary(
    RecipeJournalSummaryEntity summary,
  ) {
    final recipe = summary.recipe;
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return TemplateRenderData(
      title: recipe.title,
      primaryIngredients: summary.primaryIngredients
          .map(
            (ingredient) => TemplateIngredientData(
              name: ingredient.name,
              amountText: ingredient.amountText,
            ),
          )
          .toList(growable: false),
      category: recipe.category,
      totalMinutes: total == 0 ? null : total,
      isIncomplete: recipe.status == RecipeStatus.incomplete,
    );
  }
}
