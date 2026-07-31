import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'kitchen_app_core_app_route_names.dart';
import 'kitchen_app_core_recipe_creation_options_sheet.dart';

extension AppNavigationExtension on BuildContext {
  void goToImportInbox() => goNamed(AppRouteNames.importInbox);

  Future<T?> pushSearch<T>(String query) {
    return pushNamed<T>(AppRouteNames.search, queryParameters: {'q': query});
  }

  Future<T?> pushCreateRecipe<T>() {
    return pushNamed<T>(AppRouteNames.createRecipe);
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
