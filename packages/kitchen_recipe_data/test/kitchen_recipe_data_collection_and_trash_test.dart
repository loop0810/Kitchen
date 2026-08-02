import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/database/kitchen_recipe_data_app_database.dart';
import 'package:kitchen_recipe_data/src/collection/repositories/kitchen_recipe_data_recipe_collection_repository_impl.dart';
import 'package:kitchen_recipe_data/src/deletion/repositories/kitchen_recipe_data_recipe_deletion_repository_impl.dart';
import 'package:kitchen_recipe_data/src/recipe/repositories/kitchen_recipe_data_recipe_repository_impl.dart';
import 'package:kitchen_recipe_data/src/preferences/repositories/kitchen_recipe_data_recipe_sort_preference_repository_impl.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  late AppDatabase database;
  late RecipeRepositoryImpl recipes;
  late RecipeCollectionRepositoryImpl collections;
  late RecipeDeletionRepositoryImpl deletion;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    recipes = RecipeRepositoryImpl(database);
    collections = RecipeCollectionRepositoryImpl(database);
    deletion = RecipeDeletionRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('一道菜可属于多个集合，按创建顺序展示且删除集合不删除菜谱', () async {
    final breakfast = await collections.createCollection(name: ' 早餐 ');
    final favorites = await collections.createCollection(name: '收藏夹');
    await collections.setCollectionsForRecipe(
      recipeId: 'sample-tomato-eggs',
      collectionIds: {breakfast, favorites},
    );

    expect(await collections.getCollectionIdsForRecipe('sample-tomato-eggs'), {
      breakfast,
      favorites,
    });
    final ordered = await collections.watchCollections().first;
    expect(ordered.map((item) => item.id), [breakfast, favorites]);
    expect(ordered.first.name, '早餐');

    await collections.deleteCollection(favorites);
    expect(await recipes.getRecipeDetail('sample-tomato-eggs'), isNotNull);
    expect(await collections.getCollectionIdsForRecipe('sample-tomato-eggs'), {
      breakfast,
    });
  });

  test('集合成员替换失败时事务整体回滚', () async {
    final id = await collections.createCollection(name: '晚餐');
    await collections.appendRecipesToCollection(
      collectionId: id,
      orderedRecipeIds: ['sample-tomato-eggs'],
    );

    await expectLater(
      collections.appendRecipesToCollection(
        collectionId: id,
        orderedRecipeIds: ['sample-chicken-wings', 'missing'],
      ),
      throwsStateError,
    );
    final detail = await collections.getCollectionDetail(id);
    expect(detail!.members.map((item) => item.recipe.recipe.id), [
      'sample-tomato-eggs',
    ]);
  });

  test('成员按选择顺序追加，移除可按原位置恢复并持久化重排', () async {
    final id = await collections.createCollection(name: '顺序测试');
    await collections.appendRecipesToCollection(
      collectionId: id,
      orderedRecipeIds: [
        'sample-chicken-wings',
        'sample-tomato-eggs',
        'sample-pumpkin-soup',
      ],
    );
    expect(
      (await collections.getCollectionDetail(
        id,
      ))!.members.map((item) => item.recipe.recipe.id),
      ['sample-chicken-wings', 'sample-tomato-eggs', 'sample-pumpkin-soup'],
    );

    final removedPosition = await collections.removeRecipeFromCollection(
      collectionId: id,
      recipeId: 'sample-tomato-eggs',
    );
    expect(removedPosition, 1);
    await collections.restoreRecipeToCollection(
      collectionId: id,
      recipeId: 'sample-tomato-eggs',
      position: removedPosition,
    );
    await collections.reorderCollectionMembers(
      collectionId: id,
      orderedRecipeIds: [
        'sample-pumpkin-soup',
        'sample-tomato-eggs',
        'sample-chicken-wings',
      ],
    );
    expect(
      (await collections.getCollectionDetail(
        id,
      ))!.members.map((item) => item.recipe.recipe.id),
      ['sample-pumpkin-soup', 'sample-tomato-eggs', 'sample-chicken-wings'],
    );
  });

  test('自定义封面以受控相对路径保存，替换和删除会清理旧文件', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kitchen_collection_covers_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = RecipeCollectionRepositoryImpl(
      database,
      coverDirectoryProvider: () async => directory,
    );
    final firstBytes = Uint8List.fromList([1, 2, 3]);
    final id = await repository.createCollection(
      name: '有封面',
      coverBytes: firstBytes,
    );
    expect(
      (await repository.watchCollections().first).single.coverBytes,
      firstBytes,
    );
    expect(await directory.list().length, 1);

    final replacement = Uint8List.fromList([4, 5, 6]);
    await repository.updateCollection(
      collectionId: id,
      name: '新封面',
      coverChange: RecipeCollectionCoverChange.replace(replacement),
    );
    expect(
      (await repository.watchCollections().first).single.coverBytes,
      replacement,
    );
    expect(await directory.list().length, 1);

    await repository.deleteCollection(id);
    expect(await directory.list().isEmpty, isTrue);
  });

  test('软删除从默认库和集合隐藏，恢复保留原集合与状态', () async {
    final id = await collections.createCollection(name: '家常');
    await collections.appendRecipesToCollection(
      collectionId: id,
      orderedRecipeIds: ['sample-tomato-eggs'],
    );
    await deletion.moveToTrash('sample-tomato-eggs');

    final library = await recipes.watchRecipes(const RecipeQuery()).first;
    final trash = await recipes
        .watchRecipes(const RecipeQuery(scope: RecipeListScope.trash))
        .first;
    expect(
      library.map((item) => item.recipe.id),
      isNot(contains('sample-tomato-eggs')),
    );
    expect(
      trash
          .singleWhere((item) => item.recipe.id == 'sample-tomato-eggs')
          .recipe
          .deletedAt,
      isNotNull,
    );
    expect((await collections.getCollectionDetail(id))!.members, isEmpty);

    await deletion.restoreRecipe('sample-tomato-eggs');
    expect(
      (await recipes.getRecipeDetail('sample-tomato-eggs'))!.recipe.status,
      RecipeStatus.ready,
    );
    expect((await collections.getCollectionDetail(id))!.members, hasLength(1));
  });

  test('永久删除级联详情和集合关系，30 天边界可清理', () async {
    final id = await collections.createCollection(name: '待清理');
    await collections.appendRecipesToCollection(
      collectionId: id,
      orderedRecipeIds: ['sample-tomato-eggs', 'sample-chicken-wings'],
    );
    await deletion.moveToTrash('sample-tomato-eggs');
    await deletion.permanentlyDeleteRecipe('sample-tomato-eggs');
    expect(await recipes.getRecipeDetail('sample-tomato-eggs'), isNull);
    expect((await collections.getCollectionDetail(id))!.members, hasLength(1));

    await deletion.moveToTrash('sample-chicken-wings');
    final boundary = DateTime(2026, 1, 1);
    await (database.update(database.recipes)
          ..where((row) => row.id.equals('sample-chicken-wings')))
        .write(RecipesCompanion(deletedAt: Value(boundary)));
    expect(await deletion.purgeDeletedBefore(boundary), 1);
  });

  test('五种排序可组合查询，菜名按中文拼音、英文和符号分组', () async {
    await _insertRecipe(database, id: 'zh-bao', title: '包子');
    await _insertRecipe(database, id: 'zh-an', title: '安康鱼');
    await _insertRecipe(database, id: 'en-b', title: 'banana');
    await _insertRecipe(database, id: 'en-a', title: 'Apple');
    await _insertRecipe(database, id: 'symbol', title: '123 沙拉');

    final titled = await recipes
        .watchRecipes(const RecipeQuery(sortOrder: RecipeSortOrder.title))
        .first;
    final ids = titled.map((item) => item.recipe.id).toList();
    expect(ids.indexOf('zh-an'), lessThan(ids.indexOf('zh-bao')));
    expect(ids.indexOf('zh-bao'), lessThan(ids.indexOf('en-a')));
    expect(ids.indexOf('en-a'), lessThan(ids.indexOf('en-b')));
    expect(ids.indexOf('en-b'), lessThan(ids.indexOf('symbol')));

    for (final order in RecipeSortOrder.values) {
      expect(
        await recipes
            .watchRecipes(RecipeQuery(text: 'Apple', sortOrder: order))
            .first,
        hasLength(1),
      );
    }
  });

  test('排序偏好保存后可由新 Repository 实例读取', () async {
    await database.saveSortOrder('mostCooked');
    expect(
      await RecipeSortPreferenceRepositoryImpl(database).getSortOrder(),
      RecipeSortOrder.recentlyUpdated,
    );
  });
}

Future<void> _insertRecipe(
  AppDatabase database, {
  required String id,
  required String title,
}) {
  final now = DateTime(2026, 1, 1);
  return database
      .into(database.recipes)
      .insert(
        RecipesCompanion.insert(
          id: id,
          title: title,
          coverColor: 0xFFF4B9A8,
          createdAt: now,
          updatedAt: now,
        ),
      );
}
