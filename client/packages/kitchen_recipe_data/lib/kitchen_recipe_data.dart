import 'dart:async';

import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'src/database/kitchen_recipe_data_app_database.dart';
import 'src/recipe/policies/kitchen_recipe_data_pinyin_recipe_reading_order_policy.dart';
import 'src/recipe/repositories/kitchen_recipe_data_recipe_repository_impl.dart';
import 'src/collection/repositories/kitchen_recipe_data_recipe_collection_repository_impl.dart';
import 'src/deletion/repositories/kitchen_recipe_data_recipe_deletion_repository_impl.dart';
import 'src/preferences/repositories/kitchen_recipe_data_recipe_sort_preference_repository_impl.dart';
import 'src/personalization/repositories/kitchen_recipe_data_personal_recipe_config_repository_impl.dart';

/// Data package 对外唯一的装配入口。
///
/// 调用方只能取得 Domain Repository，无法绕过架构边界直接操作 Drift 表。
class RecipeDataModule {
  RecipeDataModule._(
    this._database, {
    PersonalRecipeConfigRemoteGateway? remoteGateway,
  }) : _readingOrderPolicy = const PinyinRecipeReadingOrderPolicy(),
       _recipeRepository = RecipeRepositoryImpl(_database),
       _collectionRepository = RecipeCollectionRepositoryImpl(_database),
       _deletionRepository = RecipeDeletionRepositoryImpl(_database),
       _sortPreferenceRepository = RecipeSortPreferenceRepositoryImpl(
         _database,
       ),
       _personalRecipeConfigRepository = PersonalRecipeConfigRepositoryImpl(
         _database,
         remoteGateway: remoteGateway,
       ) {
    // 封面文件清理是机会式维护，失败不能阻断应用组合根创建。
    unawaited(_collectionRepository.cleanupOrphanedCovers().catchError((_) {}));
  }

  factory RecipeDataModule({
    PersonalRecipeConfigRemoteGateway? remoteGateway,
  }) => RecipeDataModule._(AppDatabase(), remoteGateway: remoteGateway);

  final AppDatabase _database;
  final RecipeReadingOrderPolicy _readingOrderPolicy;
  final RecipeRepository _recipeRepository;
  final RecipeCollectionRepositoryImpl _collectionRepository;
  final RecipeDeletionRepository _deletionRepository;
  final RecipeSortPreferenceRepository _sortPreferenceRepository;
  final PersonalRecipeConfigRepository _personalRecipeConfigRepository;

  RecipeRepository get recipeRepository => _recipeRepository;
  RecipeCollectionRepository get collectionRepository => _collectionRepository;
  RecipeDeletionRepository get deletionRepository => _deletionRepository;
  RecipeSortPreferenceRepository get sortPreferenceRepository =>
      _sortPreferenceRepository;

  PersonalRecipeConfigRepository get personalRecipeConfigRepository =>
      _personalRecipeConfigRepository;

  /// 按会话创建绑定命名空间的配置 Repository；菜谱 Repository 始终共享设备资料库。
  PersonalRecipeConfigRepository personalRecipeConfigRepositoryFor(
    PersonalRecipeConfigNamespace namespace,
  ) => PersonalRecipeConfigRepositoryImpl(_database, namespace: namespace);

  /// 清除菜谱、集合、导入配置等 Recipe Data 内的设备资料。
  Future<void> clearLocalData() => _database.clearLocalData();

  /// 导出不含设备绝对路径的菜谱逻辑快照。
  Future<Map<String, dynamic>> exportLogicalData() =>
      _database.exportLogicalData();

  /// 用已验证的逻辑快照替换当前菜谱资料。
  Future<void> restoreLogicalData(Map<String, dynamic> data) =>
      _database.restoreLogicalData(data);

  /// 菜谱库与阅读器共享的中文优先标题顺序策略。
  RecipeReadingOrderPolicy get readingOrderPolicy => _readingOrderPolicy;

  Future<void> close() => _database.close();
}
