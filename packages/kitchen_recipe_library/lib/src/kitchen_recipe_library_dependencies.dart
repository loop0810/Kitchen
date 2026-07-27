import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeLibraryDependencies {
  const RecipeLibraryDependencies({
    required this.watchRecipes,
    required this.getRecipeDetail,
    required this.setFavorite,
  });

  final WatchRecipesUseCase watchRecipes;
  final GetRecipeDetailUseCase getRecipeDetail;
  final SetRecipeFavoriteUseCase setFavorite;
}

final recipeLibraryDependenciesProvider = Provider<RecipeLibraryDependencies>((
  ref,
) {
  throw StateError('RecipeLibraryDependencies must be provided by the app.');
});

final recipesProvider = StreamProvider.autoDispose
    .family<List<RecipeEntity>, RecipeQuery>((ref, query) {
      return ref.watch(recipeLibraryDependenciesProvider).watchRecipes(query);
    });

final recipeDetailProvider = FutureProvider.autoDispose
    .family<RecipeDetailEntity?, String>((ref, recipeId) {
      return ref
          .watch(recipeLibraryDependenciesProvider)
          .getRecipeDetail(recipeId);
    });
