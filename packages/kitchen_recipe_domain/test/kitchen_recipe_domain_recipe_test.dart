import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  test('WatchRecipesUseCase 将查询完整传给 Repository', () async {
    final repository = _FakeRecipeRepository();
    final useCase = WatchRecipesUseCase(repository);
    const query = RecipeQuery(
      text: '鸡蛋',
      statusFilter: RecipeStatusFilter.favorite,
    );

    await useCase(query).first;

    expect(repository.lastQuery, query);
  });

  test('SetRecipeFavoriteUseCase 将目标收藏状态传给 Repository', () async {
    final repository = _FakeRecipeRepository();
    final useCase = SetRecipeFavoriteUseCase(repository);

    await useCase(recipeId: 'recipe-1', isFavorite: true);

    expect(repository.favoriteRecipeId, 'recipe-1');
    expect(repository.favoriteValue, isTrue);
  });

  test('GetRecipeDetailUseCase 将 ID 委托给 Repository', () async {
    final repository = _FakeRecipeRepository();

    await GetRecipeDetailUseCase(repository)('recipe-detail');

    expect(repository.detailRecipeId, 'recipe-detail');
  });

  test('CreateRecipeUseCase 保持输入并传播 Repository 错误', () async {
    final repository = _FakeRecipeRepository(createError: StateError('failed'));
    const input = CreateRecipeInput(
      title: '测试',
      summary: '',
      category: '家常菜',
      ingredients: [],
      steps: [],
      templateSelection: _templateSelection,
    );

    expect(
      () => CreateRecipeUseCase(repository)(input),
      throwsA(isA<StateError>()),
    );
    expect(repository.createInput, same(input));
  });

  test('CreateRecipeUseCase 在调用 Repository 前拒绝空菜名', () async {
    final repository = _FakeRecipeRepository();
    const input = CreateRecipeInput(
      title: '   ',
      summary: '',
      category: '家常菜',
      ingredients: [],
      steps: [],
      templateSelection: _templateSelection,
    );

    expect(
      () => CreateRecipeUseCase(repository)(input),
      throwsA(
        isA<CreateRecipeValidationFailure>().having(
          (failure) => failure.errorFor(CreateRecipeValidationField.title),
          'title error',
          '请输入菜名',
        ),
      ),
    );
    expect(repository.createInput, isNull);
  });

  test('UpdateRecipeUseCase 复用校验并将稳定子项输入委托给 Repository', () async {
    final repository = _FakeRecipeRepository();
    const input = UpdateRecipeInput(
      recipeId: 'recipe-1',
      title: '更新后的菜谱',
      summary: '',
      category: '家常菜',
      ingredients: [
        UpdateRecipeIngredientInput(
          id: 'ingredient-1',
          name: '鸡蛋',
          amountText: '2 个',
          amountValue: 2,
          unit: '个',
          preparation: '打散',
          isOptional: false,
        ),
      ],
      steps: [
        UpdateRecipeStepInput(
          id: 'step-1',
          title: '准备',
          instruction: '打散鸡蛋',
          durationMinutes: 1,
          heatLevel: null,
        ),
      ],
      templateSelection: _templateSelection,
    );

    await UpdateRecipeUseCase(repository)(input);

    expect(repository.updateInput, same(input));
  });

  test('UpdateRecipeUseCase 在调用 Repository 前拒绝空菜名', () async {
    final repository = _FakeRecipeRepository();
    const input = UpdateRecipeInput(
      recipeId: 'recipe-1',
      title: ' ',
      summary: '',
      category: '家常菜',
      ingredients: [],
      steps: [],
      templateSelection: _templateSelection,
    );

    expect(
      () => UpdateRecipeUseCase(repository)(input),
      throwsA(isA<CreateRecipeValidationFailure>()),
    );
    expect(repository.updateInput, isNull);
  });

  test('创建校验为超长菜名、空分类和无效模板返回字段错误', () {
    const service = CreateRecipeValidationService();
    final failure = service(
      CreateRecipeInput(
        title: List.filled(121, '菜').join(),
        summary: '',
        category: '',
        ingredients: const [],
        steps: const [],
        templateSelection: const RecipeTemplateSelectionValueObject(
          templateId: '',
          templateVersion: 0,
        ),
      ),
    );

    expect(
      failure?.errorFor(CreateRecipeValidationField.title),
      '菜名不能超过 120 个字符',
    );
    expect(failure?.errorFor(CreateRecipeValidationField.category), '请选择主分类');
    expect(
      failure?.errorFor(CreateRecipeValidationField.template),
      '请选择可用的手账模板',
    );
    expect(failure?.firstError, '菜名不能超过 120 个字符');
  });

  test('食材文本解析在预览和保存之间提供相同结构', () {
    const parser = IngredientLineParserService();

    expect(parser('番茄：2 个').name, '番茄');
    expect(parser('番茄：2 个').amountText, '2 个');
    expect(parser('鸡腿1个').name, '鸡腿');
    expect(parser('鸡腿1个').amountText, '1个');
    expect(parser('盐少许').name, '盐');
    expect(parser('盐少许').amountText, '少许');
    expect(parser('2斤鸭掌').name, '鸭掌');
    expect(parser('2斤鸭掌').amountText, '2斤');
    expect(parser('60克生抽').name, '生抽');
    expect(parser('60克生抽').amountText, '60克');
    expect(parser('盐').amountText, '适量');
    expect(parser('  2 个').name, isEmpty);
    expect(parser('  2 个').amountText, '2 个');
  });

  test('主要食材严格保持用户顺序并最多返回四项', () {
    const service = SelectPrimaryIngredientsService();
    const ingredients = [
      IngredientEntity(
        id: 'salt',
        recipeId: 'recipe',
        name: '盐',
        amountText: '适量',
        amountValue: null,
        unit: null,
        preparation: null,
        isOptional: false,
        position: 0,
      ),
      IngredientEntity(
        id: 'tomato',
        recipeId: 'recipe',
        name: '番茄',
        amountText: '2 个',
        amountValue: 2,
        unit: '个',
        preparation: null,
        isOptional: false,
        position: 1,
      ),
    ];

    final result = service(ingredients: ingredients);

    expect(result.map((ingredient) => ingredient.name), ['盐', '番茄']);
  });
}

class _FakeRecipeRepository implements RecipeRepository {
  _FakeRecipeRepository({this.createError});

  final Object? createError;
  RecipeQuery? lastQuery;
  String? favoriteRecipeId;
  bool? favoriteValue;
  String? detailRecipeId;
  CreateRecipeInput? createInput;
  UpdateRecipeInput? updateInput;

  @override
  Future<String> createRecipe(CreateRecipeInput input) async {
    createInput = input;
    if (createError != null) throw createError!;
    return 'recipe-1';
  }

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async {
    detailRecipeId = recipeId;
    return null;
  }

  @override
  Future<void> updateRecipe(UpdateRecipeInput input) async {
    updateInput = input;
  }

  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {
    favoriteRecipeId = recipeId;
    favoriteValue = isFavorite;
  }

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    lastQuery = query;
    return Stream.value(const []);
  }
}

const _templateSelection = RecipeTemplateSelectionValueObject(
  templateId: 'builtin.journal.basic',
  templateVersion: 1,
);
