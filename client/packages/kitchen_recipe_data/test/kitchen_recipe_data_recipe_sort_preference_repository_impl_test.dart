import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/database/kitchen_recipe_data_app_database.dart';
import 'package:kitchen_recipe_data/src/preferences/repositories/kitchen_recipe_data_recipe_sort_preference_repository_impl.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  late AppDatabase database;
  late RecipeSortPreferenceRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RecipeSortPreferenceRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('从未保存偏好时返回最近更新', () async {
    expect(await repository.getSortOrder(), RecipeSortOrder.recentlyUpdated);
  });

  test('保存后的排序方式可以在下次读取时恢复', () async {
    for (final order in RecipeSortOrder.values) {
      await repository.setSortOrder(order);

      expect(await repository.getSortOrder(), order);
    }
  });

  test('遗留的烹饪历史排序值被迁移为最近更新并写回数据库', () async {
    for (final legacyValue in const ['recentlyCooked', 'mostCooked']) {
      await database.saveSortOrder(legacyValue);

      expect(await repository.getSortOrder(), RecipeSortOrder.recentlyUpdated);
      expect(
        await database.getSavedSortOrder(),
        RecipeSortOrder.recentlyUpdated.name,
      );
    }
  });

  test('无法识别的持久化值回退到最近更新但不改写数据库', () async {
    await database.saveSortOrder('unknownOrder');

    expect(await repository.getSortOrder(), RecipeSortOrder.recentlyUpdated);
    expect(await database.getSavedSortOrder(), 'unknownOrder');
  });
}
