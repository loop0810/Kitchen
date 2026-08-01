import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/database/kitchen_recipe_data_app_database.dart';
import 'package:kitchen_recipe_data/src/recipe/repositories/kitchen_recipe_data_recipe_repository_impl.dart';
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
    final tomatoEggs = recipes
        .singleWhere((summary) => summary.recipe.id == 'sample-tomato-eggs')
        .recipe;

    expect(tomatoEggs.title, '番茄炒蛋');
    expect(tomatoEggs.prepMinutes, 5);
    expect(tomatoEggs.cookMinutes, 10);
    expect(tomatoEggs.status, RecipeStatus.ready);
    expect(tomatoEggs.coverColor, 0xFFF4B9A8);
    expect(tomatoEggs.templateSelection, _templateSelection);
    final summary = recipes.singleWhere(
      (item) => item.recipe.id == 'sample-tomato-eggs',
    );
    expect(summary.primaryIngredients.map((ingredient) => ingredient.name), [
      '番茄',
      '鸡蛋',
      '盐',
      '食用油',
    ]);
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

    expect(
      ingredientResults.map((summary) => summary.recipe.title),
      contains('番茄炒蛋'),
    );
    expect(
      favoriteResults.map((summary) => summary.recipe.title),
      contains('红烧鸡翅'),
    );
    expect(
      cookedResults.map((summary) => summary.recipe.title),
      contains('红烧鸡翅'),
    );
    expect(
      incompleteResults.map((summary) => summary.recipe.title),
      contains('奶油南瓜汤'),
    );
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
      favorites.map((summary) => summary.recipe.id),
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
        templateSelection: _templateSelection,
      ),
    );

    final detail = await repository.getRecipeDetail(id);
    expect(detail!.recipe.title, '葱油拌面');
    expect(detail.recipe.status, RecipeStatus.ready);
    expect(detail.ingredients, hasLength(2));
    expect(detail.steps, hasLength(2));
    expect(detail.recipe.templateSelection, _templateSelection);
  });

  test('缺少食材或步骤的创建内容保持待完善状态', () async {
    final id = await repository.createRecipe(
      const CreateRecipeInput(
        title: '待补菜谱',
        summary: '',
        category: '其他',
        ingredients: [],
        steps: [],
        templateSelection: _templateSelection,
      ),
    );

    final detail = await repository.getRecipeDetail(id);
    expect(detail!.recipe.status, RecipeStatus.incomplete);
  });

  test('同一导入任务重复确认只返回同一道菜谱', () async {
    final input = CreateRecipeInput(
      title: '导入菜谱',
      summary: '',
      category: '家常菜',
      ingredients: ['鸡蛋 2 个'],
      steps: ['炒熟'],
      templateSelection: _templateSelection,
      importTaskId: 'import-task-1',
      sourceSnapshot: RecipeSourceSnapshot(
        originalText: '导入原文',
        publicUrl: Uri.parse('https://example.com/recipe'),
      ),
    );

    final firstId = await repository.createRecipe(input);
    final secondId = await repository.createRecipe(input);

    expect(secondId, firstId);
    expect(await database.recipeIdForImportTask('import-task-1'), firstId);
  });

  test('更新菜谱同步删除、新增和排序并保留未编辑元数据', () async {
    final before = await repository.getRecipeDetail('sample-tomato-eggs');
    final recipeBefore = before!.recipe;

    await repository.updateRecipe(
      UpdateRecipeInput(
        recipeId: recipeBefore.id,
        title: '番茄炒鸡蛋',
        summary: '更新后的简介',
        category: '家常菜',
        ingredients: [
          _ingredientInput(before.ingredients[1], name: '土鸡蛋'),
          const UpdateRecipeIngredientInput(
            id: null,
            name: '白胡椒',
            amountText: '少许',
            amountValue: null,
            unit: null,
            preparation: null,
            isOptional: false,
          ),
        ],
        steps: [
          _stepInput(before.steps[2], instruction: '混合后快速翻炒'),
          const UpdateRecipeStepInput(
            id: null,
            title: null,
            instruction: '装盘',
            durationMinutes: null,
            heatLevel: null,
          ),
        ],
        templateSelection: _templateSelection,
      ),
    );

    final after = await repository.getRecipeDetail(recipeBefore.id);
    expect(after!.recipe.title, '番茄炒鸡蛋');
    expect(after.recipe.status, RecipeStatus.ready);
    expect(after.recipe.isFavorite, recipeBefore.isFavorite);
    expect(after.recipe.cookCount, recipeBefore.cookCount);
    expect(after.recipe.createdAt, recipeBefore.createdAt);
    expect(after.tags, containsAll(before.tags));
    expect(after.ingredients.map((ingredient) => ingredient.name), [
      '土鸡蛋',
      '白胡椒',
    ]);
    expect(after.ingredients.first.id, before.ingredients[1].id);
    expect(after.ingredients.first.preparation, '打散');
    expect(after.ingredients.first.unit, '个');
    expect(after.ingredients.last.id, isNotEmpty);
    expect(after.steps.map((step) => step.instruction), ['混合后快速翻炒', '装盘']);
    expect(after.steps.first.id, before.steps[2].id);
    expect(after.steps.first.heatLevel, '中火');

    final summary = (await repository.watchRecipes(const RecipeQuery()).first)
        .singleWhere((item) => item.recipe.id == recipeBefore.id);
    expect(summary.primaryIngredients.map((item) => item.name), ['土鸡蛋', '白胡椒']);
  });

  test('更新后缺少步骤会重新标记为待完善', () async {
    final before = await repository.getRecipeDetail('sample-tomato-eggs');

    await repository.updateRecipe(
      UpdateRecipeInput(
        recipeId: before!.recipe.id,
        title: before.recipe.title,
        summary: before.recipe.summary,
        category: before.recipe.category,
        ingredients: before.ingredients.map(_ingredientInput).toList(),
        steps: const [],
        templateSelection: before.recipe.templateSelection,
      ),
    );

    final after = await repository.getRecipeDetail(before.recipe.id);
    expect(after!.recipe.status, RecipeStatus.incomplete);
    expect(after.steps, isEmpty);
  });

  test('更新事务中子表写入失败会回滚主表和已有子项', () async {
    final before = await repository.getRecipeDetail('sample-tomato-eggs');
    await database.customStatement('''
      CREATE TRIGGER reject_failed_step
      BEFORE INSERT ON recipe_steps
      WHEN NEW.instruction = '触发失败'
      BEGIN
        SELECT RAISE(ABORT, 'forced failure');
      END
    ''');

    final update = UpdateRecipeInput(
      recipeId: before!.recipe.id,
      title: '不应保留的新标题',
      summary: before.recipe.summary,
      category: before.recipe.category,
      ingredients: before.ingredients.map(_ingredientInput).toList(),
      steps: const [
        UpdateRecipeStepInput(
          id: null,
          title: null,
          instruction: '触发失败',
          durationMinutes: null,
          heatLevel: null,
        ),
      ],
      templateSelection: before.recipe.templateSelection,
    );

    await expectLater(repository.updateRecipe(update), throwsA(anything));

    final after = await repository.getRecipeDetail(before.recipe.id);
    expect(after!.recipe.title, before.recipe.title);
    expect(
      after.steps.map((step) => step.id),
      before.steps.map((step) => step.id),
    );
  });
}

UpdateRecipeIngredientInput _ingredientInput(
  IngredientEntity ingredient, {
  String? name,
}) {
  return UpdateRecipeIngredientInput(
    id: ingredient.id,
    name: name ?? ingredient.name,
    amountText: ingredient.amountText,
    amountValue: ingredient.amountValue,
    unit: ingredient.unit,
    preparation: ingredient.preparation,
    isOptional: ingredient.isOptional,
  );
}

UpdateRecipeStepInput _stepInput(RecipeStepEntity step, {String? instruction}) {
  return UpdateRecipeStepInput(
    id: step.id,
    title: step.title,
    instruction: instruction ?? step.instruction,
    durationMinutes: step.durationMinutes,
    heatLevel: step.heatLevel,
  );
}

const _templateSelection = RecipeTemplateSelectionValueObject(
  templateId: 'builtin.journal.basic',
  templateVersion: 1,
);
