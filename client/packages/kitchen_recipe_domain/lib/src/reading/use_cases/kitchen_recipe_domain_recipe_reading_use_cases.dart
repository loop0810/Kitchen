import '../../collection/repositories/kitchen_recipe_domain_recipe_collection_repository.dart';
import '../../recipe/entities/kitchen_recipe_domain_recipe_entity.dart';
import '../../recipe/entities/kitchen_recipe_domain_recipe_journal_summary_entity.dart';
import '../entities/kitchen_recipe_domain_recipe_reading_entity.dart';
import '../../recipe/repositories/kitchen_recipe_domain_recipe_repository.dart';
import '../../ingredient/services/kitchen_recipe_domain_select_primary_ingredients_service.dart';

/// 生成一次菜谱集翻阅所使用的稳定快照。
class GetRecipeCollectionReaderSnapshotUseCase {
  const GetRecipeCollectionReaderSnapshotUseCase(
    this._repository,
    this._readingOrderPolicy,
  );

  final RecipeCollectionRepository _repository;
  final RecipeReadingOrderPolicy _readingOrderPolicy;

  Future<RecipeCollectionReaderSnapshotEntity?> call(
    String collectionId,
  ) async {
    final detail = await _repository.getCollectionDetail(collectionId);
    if (detail == null) return null;
    final summaries =
        detail.members.map((member) => member.recipe).toList(growable: true)
          ..sort(_readingOrderPolicy.compare);
    return RecipeCollectionReaderSnapshotEntity(
      collection: detail.collection,
      entries: List.unmodifiable(
        summaries.map(
          (summary) => RecipeCollectionReaderEntryEntity(
            recipe: summary,
            groupLabel: _readingOrderPolicy.groupLabelFor(summary.recipe.title),
          ),
        ),
      ),
    );
  }
}

/// 重新读取一道菜的手账摘要，用于从详情返回后刷新当前阅读页。
class GetRecipeJournalSummaryUseCase {
  const GetRecipeJournalSummaryUseCase(this._repository);

  final RecipeRepository _repository;

  Future<RecipeJournalSummaryEntity?> call(String recipeId) async {
    final detail = await _repository.getRecipeDetail(recipeId);
    if (detail == null || detail.recipe.status == RecipeStatus.deleted) {
      return null;
    }
    return RecipeJournalSummaryEntity(
      recipe: detail.recipe,
      primaryIngredients: const SelectPrimaryIngredientsService()(
        ingredients: detail.ingredients,
      ),
    );
  }
}
