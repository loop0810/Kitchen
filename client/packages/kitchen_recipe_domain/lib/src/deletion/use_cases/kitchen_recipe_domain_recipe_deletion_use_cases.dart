import '../repositories/kitchen_recipe_domain_recipe_deletion_repository.dart';

class MoveRecipeToTrashUseCase {
  const MoveRecipeToTrashUseCase(this._repository);
  final RecipeDeletionRepository _repository;
  Future<void> call(String recipeId) => _repository.moveToTrash(recipeId);
}

class RestoreRecipeUseCase {
  const RestoreRecipeUseCase(this._repository);
  final RecipeDeletionRepository _repository;
  Future<void> call(String recipeId) => _repository.restoreRecipe(recipeId);
}

class PermanentlyDeleteRecipeUseCase {
  const PermanentlyDeleteRecipeUseCase(this._repository);
  final RecipeDeletionRepository _repository;
  Future<void> call(String recipeId) =>
      _repository.permanentlyDeleteRecipe(recipeId);
}

class PurgeExpiredRecipesUseCase {
  const PurgeExpiredRecipesUseCase(this._repository);
  final RecipeDeletionRepository _repository;

  /// 回收站固定保留 30 天；调用方只负责选择机会式执行时机。
  Future<int> call({DateTime? now}) => _repository.purgeDeletedBefore(
    (now ?? DateTime.now()).subtract(const Duration(days: 30)),
  );
}
