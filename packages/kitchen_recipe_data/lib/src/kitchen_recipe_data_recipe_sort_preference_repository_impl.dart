import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_data_app_database.dart';

class RecipeSortPreferenceRepositoryImpl
    implements RecipeSortPreferenceRepository {
  const RecipeSortPreferenceRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<RecipeSortOrder> getSortOrder() async {
    final value = await _database.getSavedSortOrder();
    return RecipeSortOrder.values
            .where((order) => order.name == value)
            .firstOrNull ??
        RecipeSortOrder.recentlyUpdated;
  }

  @override
  Future<void> setSortOrder(RecipeSortOrder order) =>
      _database.saveSortOrder(order.name);
}
