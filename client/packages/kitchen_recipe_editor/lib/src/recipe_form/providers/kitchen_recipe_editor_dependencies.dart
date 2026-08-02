import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeEditorDependencies {
  const RecipeEditorDependencies({
    required this.createRecipe,
    required this.getRecipeDetail,
    required this.updateRecipe,
    this.personalRecipeConfigRepository,
  });

  final CreateRecipeUseCase createRecipe;
  final GetRecipeDetailUseCase getRecipeDetail;
  final UpdateRecipeUseCase updateRecipe;
  final PersonalRecipeConfigRepository? personalRecipeConfigRepository;
}

// 编辑器只依赖创建、详情读取和更新三个 UseCase，不接触 Repository 或数据库类型。
final recipeEditorDependenciesProvider = Provider<RecipeEditorDependencies>((
  ref,
) {
  throw StateError('RecipeEditorDependencies must be provided by the app.');
});

final recipeEditorDetailProvider = FutureProvider.autoDispose
    .family<RecipeDetailEntity?, String>((ref, recipeId) {
      return ref
          .watch(recipeEditorDependenciesProvider)
          .getRecipeDetail(recipeId);
    });

final recipeEditorPersonalRecipeConfigProvider =
    StreamProvider<PersonalRecipeConfigEntity>((ref) {
      final repository = ref
          .watch(recipeEditorDependenciesProvider)
          .personalRecipeConfigRepository;
      return repository?.watchCached() ??
          Stream.value(PersonalRecipeConfigEntity.defaults);
    });
