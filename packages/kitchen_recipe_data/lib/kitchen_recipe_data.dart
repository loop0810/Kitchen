import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'src/kitchen_recipe_data_app_database.dart';
import 'src/kitchen_recipe_data_recipe_repository_impl.dart';

/// Data package 对外唯一的装配入口。
///
/// 调用方只能取得 Domain Repository，无法绕过架构边界直接操作 Drift 表。
class RecipeDataModule {
  RecipeDataModule._(this._database)
    : _recipeRepository = RecipeRepositoryImpl(_database);

  factory RecipeDataModule() => RecipeDataModule._(AppDatabase());

  final AppDatabase _database;
  final RecipeRepository _recipeRepository;

  RecipeRepository get recipeRepository => _recipeRepository;

  Future<void> close() => _database.close();
}
