import 'dart:typed_data';

import 'kitchen_recipe_domain_recipe_collection_entity.dart';

/// 菜谱集持久化契约。
abstract interface class RecipeCollectionRepository {
  /// 持续监听按创建时间升序稳定排列的全部菜谱集。
  Stream<List<RecipeCollectionEntity>> watchCollections();

  /// 读取集合详情；不存在时返回空。
  Future<RecipeCollectionDetailEntity?> getCollectionDetail(
    String collectionId,
  );

  /// 创建集合并返回其 ID。
  Future<String> createCollection({
    required String name,
    Uint8List? coverBytes,
  });

  /// 编辑集合名称及可选封面。
  Future<void> updateCollection({
    required String collectionId,
    required String name,
    required RecipeCollectionCoverChange coverChange,
  });

  /// 只删除集合及成员关系，不删除菜谱。
  Future<void> deleteCollection(String collectionId);

  /// 返回一道菜当前所属的集合 ID。
  Future<Set<String>> getCollectionIdsForRecipe(String recipeId);

  /// 原子替换一道菜所属的全部集合。
  Future<void> setCollectionsForRecipe({
    required String recipeId,
    required Set<String> collectionIds,
  });

  /// 按选择顺序把尚未存在的成员追加到末尾。
  Future<void> appendRecipesToCollection({
    required String collectionId,
    required List<String> orderedRecipeIds,
  });

  /// 移除单个成员并返回其原位置，供界面撤销。
  Future<int> removeRecipeFromCollection({
    required String collectionId,
    required String recipeId,
  });

  /// 在指定位置恢复成员，并原子调整其后成员位置。
  Future<void> restoreRecipeToCollection({
    required String collectionId,
    required String recipeId,
    required int position,
  });

  /// 原子保存当前集合全部成员的完整顺序。
  Future<void> reorderCollectionMembers({
    required String collectionId,
    required List<String> orderedRecipeIds,
  });
}
