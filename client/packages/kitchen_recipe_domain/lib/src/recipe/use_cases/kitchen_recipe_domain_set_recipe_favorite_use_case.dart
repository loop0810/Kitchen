import '../repositories/kitchen_recipe_domain_recipe_repository.dart';

class SetRecipeFavoriteUseCase {
  const SetRecipeFavoriteUseCase(this._repository);

  final RecipeRepository _repository;

  Future<void> call({required String recipeId, required bool isFavorite}) {
    return _repository.setFavorite(recipeId: recipeId, isFavorite: isFavorite);
  }
}
