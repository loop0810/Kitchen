class RecipeStepEntity {
  const RecipeStepEntity({
    required this.id,
    required this.recipeId,
    required this.position,
    required this.title,
    required this.instruction,
    required this.durationMinutes,
    required this.heatLevel,
  });

  /// 步骤记录的唯一标识。
  final String id;

  /// 所属菜谱的 ID。
  final String recipeId;

  /// 步骤在菜谱中的零基执行顺序。
  final int position;

  /// 可选的步骤小标题。
  final String? title;

  /// 用户实际阅读和执行的操作说明。
  final String instruction;

  /// 预计执行分钟数；未设置计时时为空。
  final int? durationMinutes;

  /// 火力描述，例如“小火”或“中火”；不适用时为空。
  final String? heatLevel;
}
