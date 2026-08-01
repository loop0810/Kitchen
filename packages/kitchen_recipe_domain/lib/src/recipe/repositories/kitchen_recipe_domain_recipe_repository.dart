import '../inputs/kitchen_recipe_domain_create_recipe_input.dart';
import '../entities/kitchen_recipe_domain_recipe_detail_entity.dart';
import '../entities/kitchen_recipe_domain_recipe_journal_summary_entity.dart';
import '../queries/kitchen_recipe_domain_recipe_query.dart';
import '../inputs/kitchen_recipe_domain_update_recipe_input.dart';

/// 菜谱领域需要的持久化契约。
///
/// 接口留在 Domain，SQLite/Drift 实现留在 Data，从而保证业务规则可脱离 Flutter
/// 和数据库进行单元测试。
abstract interface class RecipeRepository {
  /// 返回持续更新的列表，而不是一次性快照；底层数据变化会自动刷新页面。
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query);

  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId);

  Future<String> createRecipe(CreateRecipeInput input);

  Future<void> updateRecipe(UpdateRecipeInput input);

  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  });
}
