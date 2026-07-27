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
    );

    expect(
      () => CreateRecipeUseCase(repository)(input),
      throwsA(isA<StateError>()),
    );
    expect(repository.createInput, same(input));
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
  Stream<List<RecipeEntity>> watchRecipes(RecipeQuery query) {
    lastQuery = query;
    return Stream.value(const []);
  }
}
