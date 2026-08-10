import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  test('MoveRecipeToTrashUseCase 将菜谱 ID 委托给 Repository', () async {
    final repository = _FakeRecipeDeletionRepository();

    await MoveRecipeToTrashUseCase(repository)('recipe-1');

    expect(repository.trashedRecipeId, 'recipe-1');
  });

  test('RestoreRecipeUseCase 将菜谱 ID 委托给 Repository', () async {
    final repository = _FakeRecipeDeletionRepository();

    await RestoreRecipeUseCase(repository)('recipe-1');

    expect(repository.restoredRecipeId, 'recipe-1');
  });

  test('PermanentlyDeleteRecipeUseCase 将菜谱 ID 委托给 Repository', () async {
    final repository = _FakeRecipeDeletionRepository();

    await PermanentlyDeleteRecipeUseCase(repository)('recipe-1');

    expect(repository.permanentlyDeletedRecipeId, 'recipe-1');
  });

  test('PurgeExpiredRecipesUseCase 使用调用方时间回推 30 天作为截止时间', () async {
    final repository = _FakeRecipeDeletionRepository(purgedCount: 2);

    final purged = await PurgeExpiredRecipesUseCase(repository)(
      now: DateTime.utc(2026, 3, 31, 12),
    );

    expect(purged, 2);
    expect(repository.purgeCutoff, DateTime.utc(2026, 3, 1, 12));
  });

  test('PurgeExpiredRecipesUseCase 未指定时间时回退到当前时间', () async {
    final repository = _FakeRecipeDeletionRepository();
    final before = DateTime.now().subtract(const Duration(days: 30));

    await PurgeExpiredRecipesUseCase(repository)();

    final cutoff = repository.purgeCutoff!;
    expect(
      cutoff.isBefore(before.subtract(const Duration(minutes: 1))),
      isFalse,
    );
    expect(cutoff.isBefore(DateTime.now()), isTrue);
  });

  test('回收站用例向调用方传播 Repository 错误', () async {
    final repository = _FakeRecipeDeletionRepository(
      error: StateError('failed'),
    );

    expect(
      () => MoveRecipeToTrashUseCase(repository)('recipe-1'),
      throwsA(isA<StateError>()),
    );
  });

  test('排序偏好用例读写 Repository 中的稳定排序方式', () async {
    final repository = _FakeRecipeSortPreferenceRepository();

    await SetRecipeSortPreferenceUseCase(repository)(RecipeSortOrder.title);

    expect(
      await GetRecipeSortPreferenceUseCase(repository)(),
      RecipeSortOrder.title,
    );
  });
}

class _FakeRecipeDeletionRepository implements RecipeDeletionRepository {
  _FakeRecipeDeletionRepository({this.purgedCount = 0, this.error});

  final int purgedCount;
  final Object? error;

  String? trashedRecipeId;
  String? restoredRecipeId;
  String? permanentlyDeletedRecipeId;
  DateTime? purgeCutoff;

  void _throwIfNeeded() {
    final failure = error;
    if (failure != null) throw failure;
  }

  @override
  Future<void> moveToTrash(String recipeId) async {
    trashedRecipeId = recipeId;
    _throwIfNeeded();
  }

  @override
  Future<void> restoreRecipe(String recipeId) async {
    restoredRecipeId = recipeId;
    _throwIfNeeded();
  }

  @override
  Future<void> permanentlyDeleteRecipe(String recipeId) async {
    permanentlyDeletedRecipeId = recipeId;
    _throwIfNeeded();
  }

  @override
  Future<int> purgeDeletedBefore(DateTime cutoff) async {
    purgeCutoff = cutoff;
    _throwIfNeeded();
    return purgedCount;
  }
}

class _FakeRecipeSortPreferenceRepository
    implements RecipeSortPreferenceRepository {
  RecipeSortOrder _order = RecipeSortOrder.recentlyUpdated;

  @override
  Future<RecipeSortOrder> getSortOrder() async => _order;

  @override
  Future<void> setSortOrder(RecipeSortOrder order) async => _order = order;
}
