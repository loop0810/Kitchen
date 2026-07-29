import 'kitchen_recipe_domain_recipe_template_selection_value_object.dart';

class CreateRecipeInput {
  const CreateRecipeInput({
    required this.title,
    required this.summary,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.templateSelection,
  });

  final String title;
  final String summary;
  final String category;
  final List<String> ingredients;
  final List<String> steps;
  final RecipeTemplateSelectionValueObject templateSelection;
}
