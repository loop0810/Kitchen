class CreateRecipeInput {
  const CreateRecipeInput({
    required this.title,
    required this.summary,
    required this.category,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final String summary;
  final String category;
  final List<String> ingredients;
  final List<String> steps;
}
