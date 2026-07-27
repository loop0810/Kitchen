abstract final class AppRouteNames {
  static const home = 'home';
  static const recipes = 'recipes';
  static const importInbox = 'importInbox';
  static const profile = 'profile';
  static const search = 'search';
  static const createRecipe = 'createRecipe';
  static const recipeDetail = 'recipeDetail';

  static String searchLocation(String query) {
    return Uri(path: '/search', queryParameters: {'q': query}).toString();
  }

  static String recipeDetailLocation(String recipeId) {
    return Uri(pathSegments: ['', 'recipes', recipeId]).toString();
  }
}
