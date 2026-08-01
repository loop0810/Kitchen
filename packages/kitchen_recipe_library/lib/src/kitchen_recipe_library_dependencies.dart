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

final recipeCollectionDetailProvider = FutureProvider.autoDispose
    .family<RecipeCollectionDetailEntity?, String>((ref, collectionId) {
      final useCase = ref
          .watch(recipeLibraryDependenciesProvider)
          .getCollectionDetail;
      return useCase == null ? Future.value() : useCase(collectionId);
    });
