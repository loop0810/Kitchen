import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_data/kitchen_recipe_data.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';
import 'package:kitchen_notes/src/kitchen_notes_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KitchenNotesBootstrap());
}

class KitchenNotesBootstrap extends StatefulWidget {
  const KitchenNotesBootstrap({super.key});

  @override
  State<KitchenNotesBootstrap> createState() => _KitchenNotesBootstrapState();
}

class _KitchenNotesBootstrapState extends State<KitchenNotesBootstrap> {
  late final RecipeDataModule _recipeDataModule;

  @override
  void initState() {
    super.initState();
    _recipeDataModule = RecipeDataModule();
  }

  @override
  void dispose() {
    _recipeDataModule.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: buildRecipeFeatureOverrides(
        _recipeDataModule.recipeRepository,
      ),
      child: const KitchenNotesApp(),
    );
  }
}

List<Override> buildRecipeFeatureOverrides(RecipeRepository repository) {
  return [
    recipeLibraryDependenciesProvider.overrideWithValue(
      RecipeLibraryDependencies(
        watchRecipes: WatchRecipesUseCase(repository),
        getRecipeDetail: GetRecipeDetailUseCase(repository),
        setFavorite: SetRecipeFavoriteUseCase(repository),
      ),
    ),
    recipeEditorDependenciesProvider.overrideWithValue(
      RecipeEditorDependencies(createRecipe: CreateRecipeUseCase(repository)),
    ),
  ];
}
