import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_data_app_database.dart';

abstract final class RecipeMapper {
  static RecipeEntity toDomain(Recipe recipe) {
    return RecipeEntity(
      id: recipe.id,
      title: recipe.title,
      summary: recipe.summary,
      category: recipe.category,
      servings: recipe.servings,
      prepMinutes: recipe.prepMinutes,
      cookMinutes: recipe.cookMinutes,
      difficulty: recipe.difficulty,
      presentationStyle: recipe.presentationStyle,
      templateSelection: RecipeTemplateSelectionValueObject(
        templateId: recipe.templateId,
        templateVersion: recipe.templateVersion,
      ),
      isFavorite: recipe.isFavorite,
      lastCookedAt: recipe.lastCookedAt,
      cookCount: recipe.cookCount,
      status: _statusToDomain(recipe.status),
      coverColor: recipe.coverColor,
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
    );
  }

  static RecipeJournalSummaryEntity summaryToDomain(RecipeSummaryData summary) {
    final groups = summary.groups
        .map(
          (group) => IngredientGroupEntity(
            id: group.id,
            recipeId: group.recipeId,
            name: group.name,
            position: group.position,
          ),
        )
        .toList(growable: false);
    final ingredients = summary.ingredients
        .map(_ingredientToDomain)
        .toList(growable: false);
    return RecipeJournalSummaryEntity(
      recipe: toDomain(summary.recipe),
      primaryIngredients: const SelectPrimaryIngredientsService()(
        groups: groups,
        ingredients: ingredients,
      ),
    );
  }

  static RecipeDetailEntity detailToDomain(RecipeDetailData detail) {
    return RecipeDetailEntity(
      recipe: toDomain(detail.recipe),
      groups: detail.groups
          .map(
            (group) => IngredientGroupEntity(
              id: group.id,
              recipeId: group.recipeId,
              name: group.name,
              position: group.position,
            ),
          )
          .toList(growable: false),
      ingredients: detail.ingredients
          .map(_ingredientToDomain)
          .toList(growable: false),
      steps: detail.steps
          .map(
            (step) => RecipeStepEntity(
              id: step.id,
              recipeId: step.recipeId,
              position: step.position,
              title: step.title,
              instruction: step.instruction,
              durationMinutes: step.durationMinutes,
              heatLevel: step.heatLevel,
            ),
          )
          .toList(growable: false),
      tags: List.unmodifiable(detail.tags),
    );
  }

  static IngredientEntity _ingredientToDomain(Ingredient ingredient) {
    return IngredientEntity(
      id: ingredient.id,
      recipeId: ingredient.recipeId,
      groupId: ingredient.groupId,
      name: ingredient.name,
      amountText: ingredient.amountText,
      amountValue: ingredient.amountValue,
      unit: ingredient.unit,
      preparation: ingredient.preparation,
      isOptional: ingredient.isOptional,
      position: ingredient.position,
    );
  }

  static RecipeStatus _statusToDomain(String status) {
    return switch (status) {
      'incomplete' => RecipeStatus.incomplete,
      'archived' => RecipeStatus.archived,
      'deleted' => RecipeStatus.deleted,
      _ => RecipeStatus.ready,
    };
  }
}
