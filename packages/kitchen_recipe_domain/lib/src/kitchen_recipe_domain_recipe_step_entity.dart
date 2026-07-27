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

  final String id;
  final String recipeId;
  final int position;
  final String? title;
  final String instruction;
  final int? durationMinutes;
  final String? heatLevel;
}
