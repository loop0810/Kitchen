import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  test('阅读快照使用策略排序并携带分组', () async {
    final repository = _CollectionRepository();
    final snapshot = await GetRecipeCollectionReaderSnapshotUseCase(
      repository,
      const _ReadingOrderPolicy(),
    )('collection-1');

    expect(snapshot, isNotNull);
    expect(snapshot!.entries.map((entry) => entry.recipe.recipe.title), [
      '阿胶糕',
      'Bread',
      '123 汤',
    ]);
    expect(snapshot.entries.map((entry) => entry.groupLabel), ['A', 'B', '#']);
  });

  test('单道手账摘要排除已删除菜谱并重新选择主要食材', () async {
    final active = await GetRecipeJournalSummaryUseCase(
      _RecipeRepository(status: RecipeStatus.ready),
    )('recipe-1');
    final deleted = await GetRecipeJournalSummaryUseCase(
      _RecipeRepository(status: RecipeStatus.deleted),
    )('recipe-1');

    expect(active?.primaryIngredients.single.name, '番茄');
    expect(deleted, isNull);
  });
}

class _ReadingOrderPolicy implements RecipeReadingOrderPolicy {
  const _ReadingOrderPolicy();

  @override
  int compare(
    RecipeJournalSummaryEntity left,
    RecipeJournalSummaryEntity right,
  ) {
    final leftGroup = _group(left.recipe.title);
    final rightGroup = _group(right.recipe.title);
    final byGroup = leftGroup.compareTo(rightGroup);
    return byGroup != 0
        ? byGroup
        : left.recipe.title.compareTo(right.recipe.title);
  }

  @override
  String groupLabelFor(String title) {
    final first = title.runes.first;
    if (first >= 0x4E00 && first <= 0x9FFF) return 'A';
    if (first >= 0x41 && first <= 0x7A) return title[0].toUpperCase();
    return '#';
  }

  int _group(String title) {
    final first = title.runes.first;
    if (first >= 0x4E00 && first <= 0x9FFF) return 0;
    if (first >= 0x41 && first <= 0x7A) return 1;
    return 2;
  }
}

class _CollectionRepository implements RecipeCollectionRepository {
  @override
  Future<RecipeCollectionDetailEntity?> getCollectionDetail(String id) async {
    final now = DateTime(2026, 8, 1);
    final collection = RecipeCollectionEntity(
      id: id,
      name: '测试菜谱集',
      memberCount: 3,
      coverBytes: null,
      createdAt: now,
      updatedAt: now,
    );
    return RecipeCollectionDetailEntity(
      collection: collection,
      members: [
        _member('recipe-3', '123 汤', 0),
        _member('recipe-2', 'Bread', 1),
        _member('recipe-1', '阿胶糕', 2),
      ],
    );
  }

  RecipeCollectionMemberEntity _member(String id, String title, int position) {
    return RecipeCollectionMemberEntity(
      recipe: RecipeJournalSummaryEntity(
        recipe: _recipe(id: id, title: title),
        primaryIngredients: const [],
      ),
      addedAt: DateTime(2026, 8, 1),
      position: position,
    );
  }

  @override
  Stream<List<RecipeCollectionEntity>> watchCollections() =>
      const Stream.empty();

  @override
  Future<String> createCollection({required String name, coverBytes}) =>
      throw UnimplementedError();
  @override
  Future<void> updateCollection({
    required String collectionId,
    required String name,
    required RecipeCollectionCoverChange coverChange,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteCollection(String collectionId) =>
      throw UnimplementedError();
  @override
  Future<Set<String>> getCollectionIdsForRecipe(String recipeId) =>
      throw UnimplementedError();
  @override
  Future<void> setCollectionsForRecipe({
    required String recipeId,
    required Set<String> collectionIds,
  }) => throw UnimplementedError();
  @override
  Future<void> appendRecipesToCollection({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) => throw UnimplementedError();
  @override
  Future<int> removeRecipeFromCollection({
    required String collectionId,
    required String recipeId,
  }) => throw UnimplementedError();
  @override
  Future<void> restoreRecipeToCollection({
    required String collectionId,
    required String recipeId,
    required int position,
  }) => throw UnimplementedError();
  @override
  Future<void> reorderCollectionMembers({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) => throw UnimplementedError();
}

class _RecipeRepository implements RecipeRepository {
  const _RecipeRepository({required this.status});

  final RecipeStatus status;

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async {
    return RecipeDetailEntity(
      recipe: _recipe(id: recipeId, title: '番茄炒蛋', status: status),
      ingredients: [
        IngredientEntity(
          id: 'ingredient-1',
          recipeId: recipeId,
          name: '番茄',
          amountText: '2 个',
          amountValue: 2,
          unit: '个',
          preparation: null,
          isOptional: false,
          position: 0,
        ),
      ],
      steps: const [],
      tags: const [],
    );
  }

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) =>
      const Stream.empty();
  @override
  Future<String> createRecipe(CreateRecipeInput input) =>
      throw UnimplementedError();
  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) => throw UnimplementedError();
  @override
  Future<void> updateRecipe(UpdateRecipeInput input) =>
      throw UnimplementedError();
}

RecipeEntity _recipe({
  required String id,
  required String title,
  RecipeStatus status = RecipeStatus.ready,
}) {
  final now = DateTime(2026, 8, 1);
  return RecipeEntity(
    id: id,
    title: title,
    summary: '',
    category: '家常菜',
    servings: null,
    prepMinutes: null,
    cookMinutes: null,
    difficulty: '简单',
    presentationStyle: 'inheritDefault',
    templateSelection: const RecipeTemplateSelectionValueObject(
      templateId: 'builtin.journal.basic',
      templateVersion: 1,
    ),
    isFavorite: false,
    status: status,
    coverColor: 0xFFF4B9A8,
    createdAt: now,
    updatedAt: now,
  );
}
