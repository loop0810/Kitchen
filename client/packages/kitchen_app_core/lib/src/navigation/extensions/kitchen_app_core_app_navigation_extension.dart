import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../models/kitchen_app_core_app_route_names.dart';
import '../../recipe_creation/widgets/kitchen_app_core_recipe_creation_options_sheet.dart';

extension AppNavigationExtension on BuildContext {
  // 全局页面跳转统一从这里进入。Feature 不直接书写 path、route name 或参数键名，
  // 这样路由注册仍由壳工程负责，但页面只依赖稳定的业务语义 API。
  void goToRecipes() => goNamed(AppRouteNames.recipes);
  void goToImportInbox() => goNamed(AppRouteNames.importInbox);

  Future<T?> pushSearch<T>(String query) {
    return pushNamed<T>(AppRouteNames.search, queryParameters: {'q': query});
  }

  Future<T?> pushCreateRecipe<T>() {
    return pushNamed<T>(AppRouteNames.createRecipe);
  }

  Future<T?> pushPasteImport<T>() {
    return pushNamed<T>(AppRouteNames.pasteImport);
  }

  Future<T?> pushImageImport<T>() {
    return pushNamed<T>(AppRouteNames.imageImport);
  }

  Future<void> showRecipeCreationOptions() {
    return showRecipeCreationOptionsSheet(this);
  }

  Future<T?> pushImportTask<T>(String taskId) {
    return pushNamed<T>(
      AppRouteNames.importTask,
      pathParameters: {'id': taskId},
    );
  }

  void replaceWithImportTask(String taskId) {
    pushReplacementNamed(
      AppRouteNames.importTask,
      pathParameters: {'id': taskId},
    );
  }

  Future<T?> pushReviewImportDraft<T>(String taskId) {
    return pushNamed<T>(
      AppRouteNames.reviewImportDraft,
      pathParameters: {'id': taskId},
    );
  }

  Future<T?> pushRecipeDetail<T>(String recipeId) {
    return pushNamed<T>(
      AppRouteNames.recipeDetail,
      pathParameters: {'id': recipeId},
    );
  }

  Future<T?> pushRecipeCollection<T>(String collectionId) {
    return pushNamed<T>(
      AppRouteNames.recipeCollection,
      pathParameters: {'id': collectionId},
    );
  }

  Future<T?> pushRecipeCollectionReader<T>(String collectionId) {
    return pushNamed<T>(
      AppRouteNames.recipeCollectionReader,
      pathParameters: {'id': collectionId},
    );
  }

  Future<T?> pushRecipeTrash<T>() => pushNamed<T>(AppRouteNames.recipeTrash);

  Future<T?> pushEditRecipe<T>(String recipeId) {
    return pushNamed<T>(
      AppRouteNames.editRecipe,
      pathParameters: {'id': recipeId},
    );
  }

  void replaceWithRecipeDetail(String recipeId) {
    pushReplacementNamed(
      AppRouteNames.recipeDetail,
      pathParameters: {'id': recipeId},
    );
  }
}
