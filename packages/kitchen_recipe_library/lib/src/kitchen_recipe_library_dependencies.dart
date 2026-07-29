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
