import 'package:drift/drift.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:uuid/uuid.dart';

import 'kitchen_recipe_data_app_database.dart';
import 'kitchen_recipe_data_recipe_mapper.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(this._database);

  final AppDatabase _database;
  final _uuid = const Uuid();

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    return _database
        .watchRecipeSummaries(
          query: query.text,
          statusFilter: _statusFilterToData(query.statusFilter),
        )
        .map(
          (summaries) => summaries
              .map(RecipeMapper.summaryToDomain)
              .toList(growable: false),
        );
  }

  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) {
    return _database.setFavorite(recipeId, value: isFavorite);
  }

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async {
    final detail = await _database.getRecipeDetail(recipeId);
    return detail == null ? null : RecipeMapper.detailToDomain(detail);
  }

  @override
  Future<String> createRecipe(CreateRecipeInput input) async {
    final recipeId = _uuid.v4();
    final groupId = _uuid.v4();
    final now = DateTime.now();
    final incomplete = input.ingredients.isEmpty || input.steps.isEmpty;

    await _database.transaction(() async {
      await _database
          .into(_database.recipes)
          .insert(
            RecipesCompanion.insert(
              id: recipeId,
              title: input.title.trim(),
              summary: Value(input.summary.trim()),
              category: Value(input.category),
              templateId: Value(input.templateSelection.templateId),
              templateVersion: Value(input.templateSelection.templateVersion),
              status: Value(incomplete ? 'incomplete' : 'ready'),
              coverColor: _coverColorFor(input.title),
              createdAt: now,
              updatedAt: now,
            ),
          );

      if (input.ingredients.isNotEmpty) {
        await _database
            .into(_database.ingredientGroups)
            .insert(
              IngredientGroupsCompanion.insert(
                id: groupId,
                recipeId: recipeId,
                name: '食材',
                position: 0,
              ),
            );
        for (final (index, line) in input.ingredients.indexed) {
          final parsed = const IngredientLineParserService()(line);
          await _database
              .into(_database.ingredients)
              .insert(
                IngredientsCompanion.insert(
                  id: _uuid.v4(),
                  recipeId: recipeId,
                  groupId: Value(groupId),
                  name: parsed.name,
                  amountText: Value(parsed.amountText),
                  position: index,
                ),
              );
        }
      }

      for (final (index, instruction) in input.steps.indexed) {
        await _database
            .into(_database.recipeSteps)
            .insert(
              RecipeStepsCompanion.insert(
                id: _uuid.v4(),
                recipeId: recipeId,
                position: index,
                instruction: instruction,
              ),
            );
      }
    });
    return recipeId;
  }

  String _statusFilterToData(RecipeStatusFilter filter) {
    return switch (filter) {
      RecipeStatusFilter.all => 'all',
      RecipeStatusFilter.favorite => 'favorite',
      RecipeStatusFilter.cooked => 'cooked',
      RecipeStatusFilter.incomplete => 'incomplete',
    };
  }

  int _coverColorFor(String title) {
    const colors = [0xFFF4B9A8, 0xFFF1CA7B, 0xFFAFC5A7, 0xFFB9CBE0, 0xFFE4B8C5];
    return colors[title.hashCode.abs() % colors.length];
  }
}
