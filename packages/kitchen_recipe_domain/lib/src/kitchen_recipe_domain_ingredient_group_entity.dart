class IngredientGroupEntity {
  const IngredientGroupEntity({
    required this.id,
    required this.recipeId,
    required this.name,
    required this.position,
  });

  /// 食材分组的唯一标识。
  final String id;

  /// 所属菜谱的 ID。
  final String recipeId;

  /// 分组名称，例如“主料”或“调料”。
  final String name;

  /// 分组在菜谱中的零基排序位置。
  final int position;
}
