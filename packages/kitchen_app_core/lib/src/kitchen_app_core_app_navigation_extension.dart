import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'kitchen_app_core_app_route_names.dart';

extension AppNavigationExtension on BuildContext {
  void goToImportInbox() => goNamed(AppRouteNames.importInbox);

  Future<T?> pushSearch<T>(String query) {
    return pushNamed<T>(AppRouteNames.search, queryParameters: {'q': query});
  }

  Future<T?> pushCreateRecipe<T>() {
    return pushNamed<T>(AppRouteNames.createRecipe);
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
