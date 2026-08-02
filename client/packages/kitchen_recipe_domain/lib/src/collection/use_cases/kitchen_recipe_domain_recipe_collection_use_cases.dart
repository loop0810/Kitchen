import 'dart:typed_data';

import '../entities/kitchen_recipe_domain_recipe_collection_entity.dart';
import '../repositories/kitchen_recipe_domain_recipe_collection_repository.dart';

class WatchRecipeCollectionsUseCase {
  const WatchRecipeCollectionsUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Stream<List<RecipeCollectionEntity>> call() => _repository.watchCollections();
}

class GetRecipeCollectionDetailUseCase {
  const GetRecipeCollectionDetailUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<RecipeCollectionDetailEntity?> call(String id) =>
      _repository.getCollectionDetail(id);
}

class CreateRecipeCollectionUseCase {
  const CreateRecipeCollectionUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<String> call({required String name, Uint8List? coverBytes}) =>
      _repository.createCollection(
        name: normalizeRecipeCollectionName(name),
        coverBytes: coverBytes,
      );
}

class UpdateRecipeCollectionUseCase {
  const UpdateRecipeCollectionUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<void> call({
    required String collectionId,
    required String name,
    RecipeCollectionCoverChange coverChange =
        const RecipeCollectionCoverChange.keep(),
  }) => _repository.updateCollection(
    collectionId: collectionId,
    name: normalizeRecipeCollectionName(name),
    coverChange: coverChange,
  );
}

class DeleteRecipeCollectionUseCase {
  const DeleteRecipeCollectionUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<void> call(String id) => _repository.deleteCollection(id);
}

class GetCollectionIdsForRecipeUseCase {
  const GetCollectionIdsForRecipeUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<Set<String>> call(String recipeId) =>
      _repository.getCollectionIdsForRecipe(recipeId);
}

class SetCollectionsForRecipeUseCase {
  const SetCollectionsForRecipeUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<void> call({
    required String recipeId,
    required Set<String> collectionIds,
  }) => _repository.setCollectionsForRecipe(
    recipeId: recipeId,
    collectionIds: collectionIds,
  );
}

class AppendRecipesToCollectionUseCase {
  const AppendRecipesToCollectionUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<void> call({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) => _repository.appendRecipesToCollection(
    collectionId: collectionId,
    orderedRecipeIds: orderedRecipeIds,
  );
}

class RemoveRecipeFromCollectionUseCase {
  const RemoveRecipeFromCollectionUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<int> call({required String collectionId, required String recipeId}) =>
      _repository.removeRecipeFromCollection(
        collectionId: collectionId,
        recipeId: recipeId,
      );
}

class RestoreRecipeToCollectionUseCase {
  const RestoreRecipeToCollectionUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<void> call({
    required String collectionId,
    required String recipeId,
    required int position,
  }) => _repository.restoreRecipeToCollection(
    collectionId: collectionId,
    recipeId: recipeId,
    position: position,
  );
}

class ReorderCollectionMembersUseCase {
  const ReorderCollectionMembersUseCase(this._repository);
  final RecipeCollectionRepository _repository;
  Future<void> call({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) => _repository.reorderCollectionMembers(
    collectionId: collectionId,
    orderedRecipeIds: orderedRecipeIds,
  );
}
