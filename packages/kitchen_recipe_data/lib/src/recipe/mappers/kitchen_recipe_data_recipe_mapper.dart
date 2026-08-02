import 'dart:typed_data';

import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../../database/kitchen_recipe_data_app_database.dart';

/// Data 与 Domain 之间的翻译边界。
///
/// Drift 生成的 Row 只能停留在本 package；Feature 最终拿到的是纯 Dart 领域对象。
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
      status: _statusToDomain(recipe.status),
      coverColor: recipe.coverColor,
      createdAt: recipe.createdAt,
      updatedAt: recipe.updatedAt,
      deletedAt: recipe.deletedAt,
      statusBeforeDeletion: recipe.statusBeforeDeletion == null
          ? null
          : _statusToDomain(recipe.statusBeforeDeletion!),
    );
  }

  static RecipeJournalSummaryEntity summaryToDomain(RecipeSummaryData summary) {
    final ingredients = summary.ingredients
        .map(_ingredientToDomain)
        .toList(growable: false);
    return RecipeJournalSummaryEntity(
      recipe: toDomain(summary.recipe),
      // “最多展示哪些主料”是产品规则而不是 SQL 规则，交给 Domain Service 计算。
      primaryIngredients: const SelectPrimaryIngredientsService()(
        ingredients: ingredients,
      ),
    );
  }

  static RecipeDetailEntity detailToDomain(RecipeDetailData detail) {
    return RecipeDetailEntity(
      recipe: toDomain(detail.recipe),
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

  static RecipeCollectionEntity collectionSummaryToDomain(
    RecipeCollectionSummaryData data, {
    Uint8List? coverBytes,
  }) {
    return RecipeCollectionEntity(
      id: data.collection.id,
      name: data.collection.name,
      memberCount: data.memberCount,
      coverBytes: coverBytes,
      createdAt: data.collection.createdAt,
      updatedAt: data.collection.updatedAt,
    );
  }

  static RecipeCollectionDetailEntity collectionDetailToDomain(
    RecipeCollectionDetailData data, {
    Uint8List? coverBytes,
  }) {
    return RecipeCollectionDetailEntity(
      collection: collectionSummaryToDomain(
        data.summary,
        coverBytes: coverBytes,
      ),
      members: data.members
          .map(
            (member) => RecipeCollectionMemberEntity(
              recipe: summaryToDomain(member.recipe),
              addedAt: member.addedAt,
              position: member.position,
            ),
          )
          .toList(growable: false),
    );
  }

  static IngredientEntity _ingredientToDomain(Ingredient ingredient) {
    return IngredientEntity(
      id: ingredient.id,
      recipeId: ingredient.recipeId,
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
    // 数据库存稳定字符串，领域层使用类型安全的 enum，避免业务代码散落字符串比较。
    return switch (status) {
      'incomplete' => RecipeStatus.incomplete,
      'archived' => RecipeStatus.archived,
      'deleted' => RecipeStatus.deleted,
      _ => RecipeStatus.ready,
    };
  }
}
