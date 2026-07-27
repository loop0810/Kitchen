import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeEditorDependencies {
  const RecipeEditorDependencies({required this.createRecipe});

  final CreateRecipeUseCase createRecipe;
}

final recipeEditorDependenciesProvider = Provider<RecipeEditorDependencies>((
  ref,
) {
  throw StateError('RecipeEditorDependencies must be provided by the app.');
});
