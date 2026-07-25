import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_notes/src/data/app_database.dart';
import 'package:uuid/uuid.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(appDatabaseProvider));
});

final recipesProvider = StreamProvider.autoDispose
    .family<List<Recipe>, RecipeQuery>((ref, query) {
      return ref
          .watch(recipeRepositoryProvider)
          .watchRecipes(query: query.text, statusFilter: query.statusFilter);
    });

final recipeDetailProvider = FutureProvider.autoDispose
    .family<RecipeDetailData?, String>((ref, id) {
      return ref.watch(recipeRepositoryProvider).getRecipe(id);
    });

class RecipeQuery {
  const RecipeQuery({this.text = '', this.statusFilter = 'all'});

  final String text;
  final String statusFilter;

  @override
  bool operator ==(Object other) =>
      other is RecipeQuery &&
      other.text == text &&
      other.statusFilter == statusFilter;

  @override
  int get hashCode => Object.hash(text, statusFilter);
}

class NewRecipeInput {
  const NewRecipeInput({
    required this.title,
    required this.summary,
    required this.category,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final String summary;
  final String category;
  final List<String> ingredients;
  final List<String> steps;
}

class RecipeRepository {
  RecipeRepository(this._database);

  final AppDatabase _database;
  final _uuid = const Uuid();

  Stream<List<Recipe>> watchRecipes({
    String query = '',
    String statusFilter = 'all',
  }) {
    return _database.watchRecipes(query: query, statusFilter: statusFilter);
  }

  Future<RecipeDetailData?> getRecipe(String id) {
    return _database.getRecipeDetail(id);
  }

  Future<String> createRecipe(NewRecipeInput input) async {
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
          final parsed = _parseIngredient(line);
          await _database
              .into(_database.ingredients)
              .insert(
                IngredientsCompanion.insert(
                  id: _uuid.v4(),
                  recipeId: recipeId,
                  groupId: Value(groupId),
                  name: parsed.$1,
                  amountText: Value(parsed.$2),
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

  Future<void> toggleFavorite(Recipe recipe) {
    return _database.setFavorite(recipe.id, value: !recipe.isFavorite);
  }

  (String, String) _parseIngredient(String line) {
    final normalized = line.trim();
    final separator = RegExp(r'\s{2,}|[：:]');
    final parts = normalized.split(separator);
    if (parts.length > 1) {
      return (parts.first.trim(), parts.sublist(1).join(' ').trim());
    }
    final match = RegExp(
      r'^(.+?)\s+([\d.]+.*|适量|少许|一小把|半[个碗勺杯])$',
    ).firstMatch(normalized);
    if (match != null) return (match.group(1)!, match.group(2)!);
    return (normalized, '适量');
  }

  int _coverColorFor(String title) {
    const colors = [0xFFF4B9A8, 0xFFF1CA7B, 0xFFAFC5A7, 0xFFB9CBE0, 0xFFE4B8C5];
    return colors[title.hashCode.abs() % colors.length];
  }
}
