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
    expect(parser('盐').amountText, '适量');
  });

  test('主要食材保持顺序并将调味料组排后，最多返回四项', () {
    const service = SelectPrimaryIngredientsService();
    const groups = [
      IngredientGroupEntity(
        id: 'seasoning',
        recipeId: 'recipe',
        name: '调料',
        position: 0,
      ),
      IngredientGroupEntity(
        id: 'main',
        recipeId: 'recipe',
        name: '主料',
        position: 1,
      ),
    ];
    const ingredients = [
      IngredientEntity(
        id: 'salt',
        recipeId: 'recipe',
        groupId: 'seasoning',
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
        groupId: 'main',
        name: '番茄',
        amountText: '2 个',
        amountValue: 2,
        unit: '个',
        preparation: null,
        isOptional: false,
        position: 1,
      ),
    ];

    final result = service(groups: groups, ingredients: ingredients);

    expect(result.map((ingredient) => ingredient.name), ['番茄', '盐']);
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
