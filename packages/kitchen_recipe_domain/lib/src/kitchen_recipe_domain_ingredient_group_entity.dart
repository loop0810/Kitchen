class IngredientGroupEntity {
  const IngredientGroupEntity({
    required this.id,
    required this.recipeId,
    required this.name,
    required this.position,
  });

  final String id;
  final String recipeId;
  final String name;
  final int position;
}
