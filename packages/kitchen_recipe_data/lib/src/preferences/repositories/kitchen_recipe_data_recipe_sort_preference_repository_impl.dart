import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../../database/kitchen_recipe_data_app_database.dart';

class RecipeSortPreferenceRepositoryImpl
    implements RecipeSortPreferenceRepository {
  const RecipeSortPreferenceRepositoryImpl(this._database);
  final AppDatabase _database;

  @override
  Future<RecipeSortOrder> getSortOrder() async {
    final value = await _database.getSavedSortOrder();
    // 旧版本曾持久化依赖烹饪历史的排序值；产品范围收缩后统一回退到最近更新，
    // 避免遗留偏好让用户看到已移除的产品语义。
    if (value == 'recentlyCooked' || value == 'mostCooked') {
      await _database.saveSortOrder(RecipeSortOrder.recentlyUpdated.name);
      return RecipeSortOrder.recentlyUpdated;
    }
    return RecipeSortOrder.values
            .where((order) => order.name == value)
            .firstOrNull ??
        RecipeSortOrder.recentlyUpdated;
  }

  @override
  Future<void> setSortOrder(RecipeSortOrder order) =>
      _database.saveSortOrder(order.name);
}
