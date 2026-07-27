import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/kitchen_recipe_data_app_database.dart';
import 'package:kitchen_recipe_data/src/kitchen_recipe_data_recipe_repository_impl.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  late AppDatabase database;
  late RecipeRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RecipeRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('列表查询将 Drift Row 映射为 Domain Entity', () async {
    final recipes = await repository.watchRecipes(const RecipeQuery()).first;
    final tomatoEggs = recipes.singleWhere(
      (recipe) => recipe.id == 'sample-tomato-eggs',
    );

    expect(tomatoEggs.title, '番茄炒蛋');
    expect(tomatoEggs.prepMinutes, 5);
    expect(tomatoEggs.cookMinutes, 10);
    expect(tomatoEggs.status, RecipeStatus.ready);
    expect(tomatoEggs.coverColor, 0xFFF4B9A8);
  });

  test('列表查询保持搜索和状态筛选行为', () async {
    final ingredientResults = await repository
        .watchRecipes(const RecipeQuery(text: '鸡蛋'))
        .first;
    final favoriteResults = await repository
        .watchRecipes(
          const RecipeQuery(statusFilter: RecipeStatusFilter.favorite),
        )
        .first;
    final cookedResults = await repository
        .watchRecipes(
          const RecipeQuery(statusFilter: RecipeStatusFilter.cooked),
        )
        .first;
    final incompleteResults = await repository
        .watchRecipes(
          const RecipeQuery(statusFilter: RecipeStatusFilter.incomplete),
        )
        .first;

    expect(ingredientResults.map((recipe) => recipe.title), contains('番茄炒蛋'));
    expect(favoriteResults.map((recipe) => recipe.title), contains('红烧鸡翅'));
    expect(cookedResults.map((recipe) => recipe.title), contains('红烧鸡翅'));
    expect(incompleteResults.map((recipe) => recipe.title), contains('奶油南瓜汤'));
  });

  test('设置收藏后列表 Stream 返回目标状态', () async {
    await repository.setFavorite(
      recipeId: 'sample-tomato-eggs',
      isFavorite: true,
    );

    final favorites = await repository
        .watchRecipes(
          const RecipeQuery(statusFilter: RecipeStatusFilter.favorite),
        )
        .first;

    expect(
      favorites.map((recipe) => recipe.id),
      contains('sample-tomato-eggs'),
    );
  });

  test('详情查询只返回 Domain Entity', () async {
    final detail = await repository.getRecipeDetail('sample-tomato-eggs');

    expect(detail, isA<RecipeDetailEntity>());
    expect(detail!.ingredients, hasLength(4));
    expect(detail.steps, hasLength(3));
    expect(detail.tags, contains('快手'));
  });

  test('创建菜谱在单个事务中保存详情并标记完整状态', () async {
    final id = await repository.createRecipe(
      const CreateRecipeInput(
        title: '葱油拌面',
        summary: '快手主食',
        category: '主食',
        ingredients: ['面条  100 克', '葱  少许'],
        steps: ['煮面', '拌入葱油'],
      ),
    );

    final detail = await repository.getRecipeDetail(id);
    expect(detail!.recipe.title, '葱油拌面');
    expect(detail.recipe.status, RecipeStatus.ready);
    expect(detail.ingredients, hasLength(2));
    expect(detail.steps, hasLength(2));
  });

  test('缺少食材或步骤的创建内容保持待完善状态', () async {
    final id = await repository.createRecipe(
      const CreateRecipeInput(
        title: '待补菜谱',
        summary: '',
        category: '其他',
        ingredients: [],
        steps: [],
      ),
    );

    final detail = await repository.getRecipeDetail(id);
    expect(detail!.recipe.status, RecipeStatus.incomplete);
  });
}
