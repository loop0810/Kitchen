abstract final class AppRouteNames {
  static const home = 'home';
  static const recipes = 'recipes';
  static const importInbox = 'importInbox';
  static const profile = 'profile';
  static const search = 'search';
  static const createRecipe = 'createRecipe';
  static const editRecipe = 'editRecipe';
  static const recipeDetail = 'recipeDetail';
  static const recipeCollection = 'recipeCollection';
  static const recipeTrash = 'recipeTrash';
  static const pasteImport = 'pasteImport';
  static const imageImport = 'imageImport';
  static const importTask = 'importTask';
  static const reviewImportDraft = 'reviewImportDraft';

  static String searchLocation(String query) {
    return Uri(path: '/search', queryParameters: {'q': query}).toString();
  }

  static String recipeDetailLocation(String recipeId) {
    return Uri(pathSegments: ['', 'recipes', recipeId]).toString();
  }

  static String editRecipeLocation(String recipeId) {
    return Uri(pathSegments: ['', 'recipes', recipeId, 'edit']).toString();
  }
}
