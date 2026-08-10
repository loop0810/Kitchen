import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  test('WatchRecipeCollectionsUseCase 透传 Repository 的集合流', () async {
    final repository = _FakeRecipeCollectionRepository();

    final collections = await WatchRecipeCollectionsUseCase(repository)().first;

    expect(repository.watchCollectionsCallCount, 1);
    expect(collections.single.id, 'collection-1');
  });

  test('GetRecipeCollectionDetailUseCase 将 ID 委托给 Repository', () async {
    final repository = _FakeRecipeCollectionRepository();

    final detail = await GetRecipeCollectionDetailUseCase(repository)(
      'collection-1',
    );

    expect(repository.detailCollectionId, 'collection-1');
    expect(detail?.collection.id, 'collection-1');
  });

  test('GetRecipeCollectionDetailUseCase 在集合不存在时返回空', () async {
    final repository = _FakeRecipeCollectionRepository(hasDetail: false);

    expect(
      await GetRecipeCollectionDetailUseCase(repository)('missing'),
      isNull,
    );
  });

  test('CreateRecipeCollectionUseCase 去除名称首尾空格并保留封面字节', () async {
    final repository = _FakeRecipeCollectionRepository();
    final cover = Uint8List.fromList([1, 2, 3]);

    final id = await CreateRecipeCollectionUseCase(repository)(
      name: '  夏日凉菜  ',
      coverBytes: cover,
    );

    expect(id, 'created-collection');
    expect(repository.createdName, '夏日凉菜');
    expect(repository.createdCoverBytes, same(cover));
  });

  test('CreateRecipeCollectionUseCase 在调用 Repository 前拒绝空名称', () async {
    final repository = _FakeRecipeCollectionRepository();

    expect(
      () => CreateRecipeCollectionUseCase(repository)(name: '   '),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.createdName, isNull);
  });

  test('CreateRecipeCollectionUseCase 在调用 Repository 前拒绝超长名称', () async {
    final repository = _FakeRecipeCollectionRepository();

    expect(
      () => CreateRecipeCollectionUseCase(repository)(name: '菜' * 41),
      throwsA(isA<ArgumentError>()),
    );
    expect(repository.createdName, isNull);
  });

  test('normalizeRecipeCollectionName 按字符数而不是字节数限制长度', () {
    expect(normalizeRecipeCollectionName('菜' * 40), '菜' * 40);
  });

  test('UpdateRecipeCollectionUseCase 默认保留封面并标准化名称', () async {
    final repository = _FakeRecipeCollectionRepository();

    await UpdateRecipeCollectionUseCase(repository)(
      collectionId: 'collection-1',
      name: ' 家常小炒 ',
    );

    expect(repository.updatedCollectionId, 'collection-1');
    expect(repository.updatedName, '家常小炒');
    expect(
      repository.updatedCoverChange?.kind,
      RecipeCollectionCoverChangeKind.keep,
    );
    expect(repository.updatedCoverChange?.bytes, isNull);
  });

  test('UpdateRecipeCollectionUseCase 透传替换封面的字节', () async {
    final repository = _FakeRecipeCollectionRepository();
    final cover = Uint8List.fromList([9, 9]);

    await UpdateRecipeCollectionUseCase(repository)(
      collectionId: 'collection-1',
      name: '家常小炒',
      coverChange: RecipeCollectionCoverChange.replace(cover),
    );

    expect(
      repository.updatedCoverChange?.kind,
      RecipeCollectionCoverChangeKind.replace,
    );
    expect(repository.updatedCoverChange?.bytes, same(cover));
  });

  test('UpdateRecipeCollectionUseCase 透传删除封面的变更', () async {
    final repository = _FakeRecipeCollectionRepository();

    await UpdateRecipeCollectionUseCase(repository)(
      collectionId: 'collection-1',
      name: '家常小炒',
      coverChange: const RecipeCollectionCoverChange.remove(),
    );

    expect(
      repository.updatedCoverChange?.kind,
      RecipeCollectionCoverChangeKind.remove,
    );
  });

  test('DeleteRecipeCollectionUseCase 只删除集合本身', () async {
    final repository = _FakeRecipeCollectionRepository();

    await DeleteRecipeCollectionUseCase(repository)('collection-1');

    expect(repository.deletedCollectionId, 'collection-1');
  });

  test('GetCollectionIdsForRecipeUseCase 返回菜谱当前所属集合', () async {
    final repository = _FakeRecipeCollectionRepository();

    final ids = await GetCollectionIdsForRecipeUseCase(repository)('recipe-1');

    expect(repository.queriedRecipeId, 'recipe-1');
    expect(ids, {'collection-1'});
  });

  test('SetCollectionsForRecipeUseCase 原子替换整组集合关系', () async {
    final repository = _FakeRecipeCollectionRepository();

    await SetCollectionsForRecipeUseCase(repository)(
      recipeId: 'recipe-1',
      collectionIds: {'collection-1', 'collection-2'},
    );

    expect(repository.setRecipeId, 'recipe-1');
    expect(repository.setCollectionIds, {'collection-1', 'collection-2'});
  });

  test('AppendRecipesToCollectionUseCase 保留选择顺序', () async {
    final repository = _FakeRecipeCollectionRepository();

    await AppendRecipesToCollectionUseCase(repository)(
      collectionId: 'collection-1',
      orderedRecipeIds: const ['recipe-2', 'recipe-1'],
    );

    expect(repository.appendedCollectionId, 'collection-1');
    expect(repository.appendedRecipeIds, ['recipe-2', 'recipe-1']);
  });

  test('RemoveRecipeFromCollectionUseCase 返回原位置供界面撤销', () async {
    final repository = _FakeRecipeCollectionRepository(removedPosition: 3);

    final position = await RemoveRecipeFromCollectionUseCase(repository)(
      collectionId: 'collection-1',
      recipeId: 'recipe-1',
    );

    expect(position, 3);
    expect(repository.removedCollectionId, 'collection-1');
    expect(repository.removedRecipeId, 'recipe-1');
  });

  test('RestoreRecipeToCollectionUseCase 透传恢复位置', () async {
    final repository = _FakeRecipeCollectionRepository();

    await RestoreRecipeToCollectionUseCase(repository)(
      collectionId: 'collection-1',
      recipeId: 'recipe-1',
      position: 2,
    );

    expect(repository.restoredCollectionId, 'collection-1');
    expect(repository.restoredRecipeId, 'recipe-1');
    expect(repository.restoredPosition, 2);
  });

  test('ReorderCollectionMembersUseCase 透传完整顺序', () async {
    final repository = _FakeRecipeCollectionRepository();

    await ReorderCollectionMembersUseCase(repository)(
      collectionId: 'collection-1',
      orderedRecipeIds: const ['recipe-3', 'recipe-1', 'recipe-2'],
    );

    expect(repository.reorderedCollectionId, 'collection-1');
    expect(repository.reorderedRecipeIds, ['recipe-3', 'recipe-1', 'recipe-2']);
  });

  test('集合用例向调用方传播 Repository 错误', () async {
    final repository = _FakeRecipeCollectionRepository(
      error: StateError('failed'),
    );

    expect(
      () => DeleteRecipeCollectionUseCase(repository)('collection-1'),
      throwsA(isA<StateError>()),
    );
  });
}

RecipeCollectionEntity _collection(String id) {
  return RecipeCollectionEntity(
    id: id,
    name: '夏日凉菜',
    memberCount: 1,
    coverBytes: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

class _FakeRecipeCollectionRepository implements RecipeCollectionRepository {
  _FakeRecipeCollectionRepository({
    this.removedPosition = 0,
    this.error,
    bool hasDetail = true,
  }) : _detail = hasDetail
           ? RecipeCollectionDetailEntity(
               collection: _collection('collection-1'),
               members: const [],
             )
           : null;

  final int removedPosition;
  final Object? error;
  final RecipeCollectionDetailEntity? _detail;

  int watchCollectionsCallCount = 0;
  String? detailCollectionId;
  String? createdName;
  Uint8List? createdCoverBytes;
  String? updatedCollectionId;
  String? updatedName;
  RecipeCollectionCoverChange? updatedCoverChange;
  String? deletedCollectionId;
  String? queriedRecipeId;
  String? setRecipeId;
  Set<String>? setCollectionIds;
  String? appendedCollectionId;
  List<String>? appendedRecipeIds;
  String? removedCollectionId;
  String? removedRecipeId;
  String? restoredCollectionId;
  String? restoredRecipeId;
  int? restoredPosition;
  String? reorderedCollectionId;
  List<String>? reorderedRecipeIds;

  void _throwIfNeeded() {
    final failure = error;
    if (failure != null) throw failure;
  }

  @override
  Stream<List<RecipeCollectionEntity>> watchCollections() {
    watchCollectionsCallCount++;
    return Stream.value([_collection('collection-1')]);
  }

  @override
  Future<RecipeCollectionDetailEntity?> getCollectionDetail(
    String collectionId,
  ) async {
    detailCollectionId = collectionId;
    _throwIfNeeded();
    return _detail;
  }

  @override
  Future<String> createCollection({
    required String name,
    Uint8List? coverBytes,
  }) async {
    createdName = name;
    createdCoverBytes = coverBytes;
    _throwIfNeeded();
    return 'created-collection';
  }

  @override
  Future<void> updateCollection({
    required String collectionId,
    required String name,
    required RecipeCollectionCoverChange coverChange,
  }) async {
    updatedCollectionId = collectionId;
    updatedName = name;
    updatedCoverChange = coverChange;
    _throwIfNeeded();
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    deletedCollectionId = collectionId;
    _throwIfNeeded();
  }

  @override
  Future<Set<String>> getCollectionIdsForRecipe(String recipeId) async {
    queriedRecipeId = recipeId;
    _throwIfNeeded();
    return {'collection-1'};
  }

  @override
  Future<void> setCollectionsForRecipe({
    required String recipeId,
    required Set<String> collectionIds,
  }) async {
    setRecipeId = recipeId;
    setCollectionIds = collectionIds;
    _throwIfNeeded();
  }

  @override
  Future<void> appendRecipesToCollection({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) async {
    appendedCollectionId = collectionId;
    appendedRecipeIds = orderedRecipeIds;
    _throwIfNeeded();
  }

  @override
  Future<int> removeRecipeFromCollection({
    required String collectionId,
    required String recipeId,
  }) async {
    removedCollectionId = collectionId;
    removedRecipeId = recipeId;
    _throwIfNeeded();
    return removedPosition;
  }

  @override
  Future<void> restoreRecipeToCollection({
    required String collectionId,
    required String recipeId,
    required int position,
  }) async {
    restoredCollectionId = collectionId;
    restoredRecipeId = recipeId;
    restoredPosition = position;
    _throwIfNeeded();
  }

  @override
  Future<void> reorderCollectionMembers({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) async {
    reorderedCollectionId = collectionId;
    reorderedRecipeIds = orderedRecipeIds;
    _throwIfNeeded();
  }
}
