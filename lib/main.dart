import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_data/kitchen_recipe_data.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';
import 'package:kitchen_notes/src/kitchen_notes_app.dart';

void main() {
  // 数据库连接依赖 Flutter 插件提供的应用目录，因此要先初始化绑定。
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KitchenNotesBootstrap());
}

/// 应用的“组合根”：只在这里创建基础设施，并把实现注入各个 Feature。
///
/// Feature 只认识 Domain 中的 UseCase/Repository 接口，不直接依赖 Drift 数据库。
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
    // App 生命周期结束时关闭 Drift，释放后台 isolate 和 SQLite 文件句柄。
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
  // Riverpod override 是根 App 向 Feature 注入依赖的入口。这样 Feature 可以独立测试，
  // 测试时也能用内存实现替换真实数据库。
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
