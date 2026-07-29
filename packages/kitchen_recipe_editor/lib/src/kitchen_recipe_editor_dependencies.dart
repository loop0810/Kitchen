import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeEditorDependencies {
  const RecipeEditorDependencies({required this.createRecipe});

  final CreateRecipeUseCase createRecipe;
}

// 编辑器只依赖创建菜谱这一项业务能力，不接触 Repository 或数据库类型。
final recipeEditorDependenciesProvider = Provider<RecipeEditorDependencies>((
  ref,
) {
  throw StateError('RecipeEditorDependencies must be provided by the app.');
});
