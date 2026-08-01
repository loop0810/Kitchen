/// 菜谱回收站生命周期契约。
abstract interface class RecipeDeletionRepository {
  /// 将菜谱软删除，并保留删除前状态和集合关系。
  Future<void> moveToTrash(String recipeId);

  /// 恢复菜谱到删除前状态。
  Future<void> restoreRecipe(String recipeId);

  /// 永久删除菜谱及其从属数据。
  Future<void> permanentlyDeleteRecipe(String recipeId);

  /// 永久删除删除时间早于或等于截止时间的菜谱，并返回清理数量。
  Future<int> purgeDeletedBefore(DateTime cutoff);
}
