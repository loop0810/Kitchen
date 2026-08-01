import 'dart:async';

import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'src/kitchen_recipe_data_app_database.dart';
import 'src/kitchen_recipe_data_recipe_repository_impl.dart';
import 'src/kitchen_recipe_data_recipe_collection_repository_impl.dart';
import 'src/kitchen_recipe_data_recipe_deletion_repository_impl.dart';
import 'src/kitchen_recipe_data_recipe_sort_preference_repository_impl.dart';

/// Data package 对外唯一的装配入口。
///
/// 调用方只能取得 Domain Repository，无法绕过架构边界直接操作 Drift 表。
class RecipeDataModule {
  RecipeDataModule._(this._database)
    : _recipeRepository = RecipeRepositoryImpl(_database),
      _collectionRepository = RecipeCollectionRepositoryImpl(_database),
      _deletionRepository = RecipeDeletionRepositoryImpl(_database),
      _sortPreferenceRepository = RecipeSortPreferenceRepositoryImpl(
        _database,
      ) {
    // 封面文件清理是机会式维护，失败不能阻断应用组合根创建。
    unawaited(_collectionRepository.cleanupOrphanedCovers().catchError((_) {}));
  }

  factory RecipeDataModule() => RecipeDataModule._(AppDatabase());

  final AppDatabase _database;
  final RecipeRepository _recipeRepository;
  final RecipeCollectionRepositoryImpl _collectionRepository;
  final RecipeDeletionRepository _deletionRepository;
  final RecipeSortPreferenceRepository _sortPreferenceRepository;

  RecipeRepository get recipeRepository => _recipeRepository;
  RecipeCollectionRepository get collectionRepository => _collectionRepository;
  RecipeDeletionRepository get deletionRepository => _deletionRepository;
  RecipeSortPreferenceRepository get sortPreferenceRepository =>
      _sortPreferenceRepository;

  Future<void> close() => _database.close();
}
