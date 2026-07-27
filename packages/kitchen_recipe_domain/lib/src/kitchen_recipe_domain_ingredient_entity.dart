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

  final String id;
  final String recipeId;
  final String? groupId;
  final String name;
  final String amountText;
  final double? amountValue;
  final String? unit;
  final String? preparation;
  final bool isOptional;
  final int position;
}
