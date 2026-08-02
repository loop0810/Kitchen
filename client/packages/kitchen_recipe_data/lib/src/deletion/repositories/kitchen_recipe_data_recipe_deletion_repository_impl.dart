import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../../database/kitchen_recipe_data_app_database.dart';

class RecipeDeletionRepositoryImpl implements RecipeDeletionRepository {
  const RecipeDeletionRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<void> moveToTrash(String recipeId) =>
      _database.moveRecipeToTrash(recipeId);

  @override
  Future<void> restoreRecipe(String recipeId) =>
      _database.restoreRecipeFromTrash(recipeId);

  @override
  Future<void> permanentlyDeleteRecipe(String recipeId) async {
    final deleted = await _database.permanentlyDeleteRecipe(recipeId);
    if (deleted == 0) throw StateError('Deleted recipe does not exist.');
  }

  @override
  Future<int> purgeDeletedBefore(DateTime cutoff) =>
      _database.purgeDeletedBefore(cutoff);
}
