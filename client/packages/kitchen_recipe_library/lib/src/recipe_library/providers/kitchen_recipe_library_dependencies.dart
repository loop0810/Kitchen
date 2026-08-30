import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeLibraryDependencies {
  const RecipeLibraryDependencies({
    required this.watchRecipes,
    required this.getRecipeDetail,
    required this.setFavorite,
    this.watchCollections,
    this.getCollectionDetail,
    this.createCollection,
    this.updateCollection,
    this.deleteCollection,
    this.getCollectionIdsForRecipe,
    this.setCollectionsForRecipe,
    this.appendRecipesToCollection,
    this.removeRecipeFromCollection,
    this.restoreRecipeToCollection,
    this.reorderCollectionMembers,
    this.getCollectionReaderSnapshot,
    this.getRecipeJournalSummary,
    this.moveToTrash,
    this.restoreRecipe,
    this.permanentlyDeleteRecipe,
    this.purgeExpiredRecipes,
    this.getSortPreference,
    this.setSortPreference,
  });

  final WatchRecipesUseCase watchRecipes;
  final GetRecipeDetailUseCase getRecipeDetail;
  final SetRecipeFavoriteUseCase setFavorite;
  final WatchRecipeCollectionsUseCase? watchCollections;
  final GetRecipeCollectionDetailUseCase? getCollectionDetail;
  final CreateRecipeCollectionUseCase? createCollection;
  final UpdateRecipeCollectionUseCase? updateCollection;
  final DeleteRecipeCollectionUseCase? deleteCollection;
  final GetCollectionIdsForRecipeUseCase? getCollectionIdsForRecipe;
  final SetCollectionsForRecipeUseCase? setCollectionsForRecipe;
  final AppendRecipesToCollectionUseCase? appendRecipesToCollection;
  final RemoveRecipeFromCollectionUseCase? removeRecipeFromCollection;
  final RestoreRecipeToCollectionUseCase? restoreRecipeToCollection;
  final ReorderCollectionMembersUseCase? reorderCollectionMembers;
  final GetRecipeCollectionReaderSnapshotUseCase? getCollectionReaderSnapshot;
  final GetRecipeJournalSummaryUseCase? getRecipeJournalSummary;
  final MoveRecipeToTrashUseCase? moveToTrash;
  final RestoreRecipeUseCase? restoreRecipe;
  final PermanentlyDeleteRecipeUseCase? permanentlyDeleteRecipe;
  final PurgeExpiredRecipesUseCase? purgeExpiredRecipes;
  final GetRecipeSortPreferenceUseCase? getSortPreference;
  final SetRecipeSortPreferenceUseCase? setSortPreference;
}

// Feature 声明自己需要哪些 UseCase，具体实现由根 App 通过 override 注入。
// 默认直接抛错可以尽早暴露“忘记装配依赖”，而不是到某次数据库操作才失败。
final recipeLibraryDependenciesProvider = Provider<RecipeLibraryDependencies>((
  ref,
) {
  throw StateError('RecipeLibraryDependencies must be provided by the app.');
});

final recipesProvider = StreamProvider.autoDispose
    .family<List<RecipeJournalSummaryEntity>, RecipeQuery>((ref, query) {
      // family 让不同搜索词/筛选条件拥有独立缓存；autoDispose 在页面离开后取消订阅。
      return ref.watch(recipeLibraryDependenciesProvider).watchRecipes(query);
    });

final recipeDetailProvider = FutureProvider.autoDispose
    .family<RecipeDetailEntity?, String>((ref, recipeId) {
      return ref
          .watch(recipeLibraryDependenciesProvider)
          .getRecipeDetail(recipeId);
    });

final recipeCollectionsProvider =
    StreamProvider.autoDispose<List<RecipeCollectionEntity>>((ref) {
      final useCase = ref
          .watch(recipeLibraryDependenciesProvider)
          .watchCollections;
      return useCase == null ? Stream.value(const []) : useCase();
    });

/// 菜谱集页的搜索结果，同时覆盖集合名称和集合成员菜谱。
///
/// 集合摘要只保存成员数量，成员菜谱由详情 UseCase 提供；因此搜索逻辑放在
/// Feature provider 中组合两个已有的本地查询，不把展示层细节下沉到 Domain/Data。
final recipeCollectionsSearchProvider = FutureProvider.autoDispose
    .family<List<RecipeCollectionEntity>, String>((ref, query) async {
      final collections = await ref.watch(recipeCollectionsProvider.future);
      final normalizedQuery = query.trim();
      if (normalizedQuery.isEmpty) return collections;

      final dependencies = ref.watch(recipeLibraryDependenciesProvider);
      final getDetail = dependencies.getCollectionDetail;
      final foldedQuery = normalizedQuery.toLowerCase();
      final nameMatches = collections
          .where(
            (collection) => collection.name.toLowerCase().contains(foldedQuery),
          )
          .toList(growable: false);
      if (getDetail == null || nameMatches.length == collections.length) {
        return nameMatches;
      }

      final matches = await ref.watch(
        recipesProvider(
          RecipeQuery(
            text: normalizedQuery,
            statusFilter: RecipeStatusFilter.all,
          ),
        ).future,
      );
      final matchingRecipeIds = matches.map((item) => item.recipe.id).toSet();

      final filtered = await Future.wait(
        collections.map((collection) async {
          if (nameMatches.contains(collection)) return collection;
          try {
            final detail = await getDetail(collection.id);
            final containsMatchingRecipe = detail?.members.any(
              (member) => matchingRecipeIds.contains(member.recipe.recipe.id),
            );
            return containsMatchingRecipe == true ? collection : null;
          } catch (_) {
            // 集合名称仍可搜索；单个集合详情失败不应阻断其他结果。
            return null;
          }
        }),
      );
      return filtered.whereType<RecipeCollectionEntity>().toList(
        growable: false,
      );
    });

final recipeCollectionDetailProvider = FutureProvider.autoDispose
    .family<RecipeCollectionDetailEntity?, String>((ref, collectionId) {
      final useCase = ref
          .watch(recipeLibraryDependenciesProvider)
          .getCollectionDetail;
      return useCase == null ? Future.value() : useCase(collectionId);
    });

final recipeCollectionReaderSnapshotProvider = FutureProvider.autoDispose
    .family<RecipeCollectionReaderSnapshotEntity?, String>((ref, collectionId) {
      final useCase = ref
          .watch(recipeLibraryDependenciesProvider)
          .getCollectionReaderSnapshot;
      return useCase == null ? Future.value() : useCase(collectionId);
    });
