class IngredientEntity {
  const IngredientEntity({
    required this.id,
    required this.recipeId,
    required this.groupId,
    required this.name,
    required this.amountText,
    required this.amountValue,
    required this.unit,
    required this.preparation,
    required this.isOptional,
    required this.position,
  });

  /// 食材记录的唯一标识。
  final String id;

  /// 所属菜谱的 ID。
  final String recipeId;

  /// 所属食材分组 ID；为空表示该食材尚未分组。
  final String? groupId;

  /// 食材名称，例如“番茄”。
  final String name;

  /// 面向用户展示的完整用量文本，例如“少许”或“2 个”。
  final String amountText;

  /// 可参与份量换算的数值；自然语言用量无法量化时为空。
  final double? amountValue;

  /// 结构化计量单位，例如“克”或“ml”；未解析出单位时为空。
  final String? unit;

  /// 使用前的处理方式，例如“切块”或“提前泡发”。
  final String? preparation;

  /// 是否属于可以省略的食材。
  final bool isOptional;

  /// 食材在菜谱中的零基排序位置。
  final int position;
}
