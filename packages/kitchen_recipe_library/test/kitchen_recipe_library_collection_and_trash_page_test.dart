import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';

void main() {
  testWidgets('菜谱库分段展示集合空状态并可创建集合', (tester) async {
    final collections = _CollectionRepository();
    await tester.pumpWidget(_app(collections: collections));
    await tester.pumpAndSettle();

    expect(find.text('菜谱'), findsOneWidget);
    expect(find.text('菜谱集'), findsOneWidget);
    await tester.tap(find.text('菜谱集'));
    await tester.pumpAndSettle();
    expect(find.text('把常做的菜整理进菜谱集'), findsOneWidget);
    await tester.tap(find.text('创建菜谱集'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  周末菜单  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(collections.createdName, '周末菜单');
  });

  testWidgets('空集合详情显示添加引导且不显示翻阅入口', (tester) async {
    final collections = _CollectionRepository(detail: _emptyCollectionDetail);
    await tester.pumpWidget(
      _app(
        collections: collections,
        page: const RecipeCollectionDetailPage(collectionId: 'collection-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('这个菜谱集还没有菜谱'), findsOneWidget);
    expect(find.text('添加菜谱'), findsOneWidget);
    expect(find.textContaining('翻阅'), findsNothing);
  });

  testWidgets('左右滑动同步分段并保留菜谱搜索与筛选状态', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '番茄');
    await tester.tap(find.text('收藏'));
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('把常做的菜整理进菜谱集'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '番茄'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '收藏')).selected,
      isTrue,
    );
  });

  testWidgets('菜谱集书籍单击不导航，长按显示管理菜单', (tester) async {
    final collections = _CollectionRepository(detail: _emptyCollectionDetail);
    await tester.pumpWidget(_app(collections: collections));
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜谱集'));
    await tester.pumpAndSettle();

    final book = find.byKey(const ValueKey('collection-1'));
    await tester.ensureVisible(book);
    await tester.tap(book);
    await tester.pumpAndSettle();
    expect(find.text('我的菜谱'), findsOneWidget);
    await tester.longPress(book);
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('管理成员'), findsOneWidget);
    expect(find.text('删除菜谱集'), findsOneWidget);
  });

  testWidgets('回收站展示保留时间并支持恢复', (tester) async {
    final deletion = _DeletionRepository();
    await tester.pumpWidget(
      _app(deletion: deletion, page: const RecipeTrashPage()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('天后自动清理'), findsOneWidget);
    await tester.tap(find.byTooltip('管理已删除菜谱'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(deletion.restoredId, 'recipe-1');
  });

  testWidgets('长按菜谱可直接确认移入回收站', (tester) async {
    final deletion = _DeletionRepository();
    await tester.pumpWidget(_app(deletion: deletion, showActiveRecipe: true));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('可管理菜谱'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移入回收站'));
    await tester.pumpAndSettle();
    expect(find.text('移入回收站？'), findsOneWidget);
    await tester.tap(find.text('移入回收站'));
    await tester.pumpAndSettle();

    expect(deletion.movedId, 'active-recipe');
  });
}

Widget _app({
  _CollectionRepository? collections,
  _DeletionRepository? deletion,
  bool showActiveRecipe = false,
  Widget page = const RecipeLibraryPage(),
}) {
  final recipeRepository = _RecipeRepository(
    showActiveRecipe: showActiveRecipe,
  );
  final collectionRepository = collections ?? _CollectionRepository();
  final deletionRepository = deletion ?? _DeletionRepository();
  return ProviderScope(
    overrides: [
      recipeLibraryDependenciesProvider.overrideWithValue(
        RecipeLibraryDependencies(
          watchRecipes: WatchRecipesUseCase(recipeRepository),
          getRecipeDetail: GetRecipeDetailUseCase(recipeRepository),
          setFavorite: SetRecipeFavoriteUseCase(recipeRepository),
          watchCollections: WatchRecipeCollectionsUseCase(collectionRepository),
          getCollectionDetail: GetRecipeCollectionDetailUseCase(
            collectionRepository,
          ),
          createCollection: CreateRecipeCollectionUseCase(collectionRepository),
          getCollectionIdsForRecipe: GetCollectionIdsForRecipeUseCase(
            collectionRepository,
          ),
          setCollectionsForRecipe: SetCollectionsForRecipeUseCase(
            collectionRepository,
          ),
          appendRecipesToCollection: AppendRecipesToCollectionUseCase(
            collectionRepository,
          ),
          removeRecipeFromCollection: RemoveRecipeFromCollectionUseCase(
            collectionRepository,
          ),
          restoreRecipeToCollection: RestoreRecipeToCollectionUseCase(
            collectionRepository,
          ),
          reorderCollectionMembers: ReorderCollectionMembersUseCase(
            collectionRepository,
          ),
          purgeExpiredRecipes: PurgeExpiredRecipesUseCase(deletionRepository),
          restoreRecipe: RestoreRecipeUseCase(deletionRepository),
          permanentlyDeleteRecipe: PermanentlyDeleteRecipeUseCase(
            deletionRepository,
          ),
          moveToTrash: MoveRecipeToTrashUseCase(deletionRepository),
        ),
      ),
    ],
    child: MaterialApp(home: page),
  );
}

final _now = DateTime.now();
final _recipe = RecipeEntity(
  id: 'recipe-1',
  title: '已删除菜谱',
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
  lastCookedAt: null,
  cookCount: 0,
  status: RecipeStatus.deleted,
  coverColor: 0xFFF4B9A8,
  createdAt: _now,
  updatedAt: _now,
  deletedAt: _now,
  statusBeforeDeletion: RecipeStatus.ready,
);
final _summary = RecipeJournalSummaryEntity(
  recipe: _recipe,
  primaryIngredients: const [],
);
final _activeSummary = RecipeJournalSummaryEntity(
  recipe: RecipeEntity(
    id: 'active-recipe',
    title: '可管理菜谱',
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
    lastCookedAt: null,
    cookCount: 0,
    status: RecipeStatus.ready,
    coverColor: 0xFFF4B9A8,
    createdAt: _now,
    updatedAt: _now,
  ),
  primaryIngredients: const [],
);
final _emptyCollection = RecipeCollectionEntity(
  id: 'collection-1',
  name: '周末菜单',
  memberCount: 0,
  coverBytes: null,
  createdAt: _now,
  updatedAt: _now,
);
final _emptyCollectionDetail = RecipeCollectionDetailEntity(
  collection: _emptyCollection,
  members: const [],
);

class _RecipeRepository implements RecipeRepository {
  _RecipeRepository({required this.showActiveRecipe});

  final bool showActiveRecipe;

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) =>
      Stream.value(
        query.scope == RecipeListScope.trash
            ? [_summary]
            : showActiveRecipe
            ? [_activeSummary]
            : const [],
      );
  @override
  Future<String> createRecipe(CreateRecipeInput input) async => 'recipe-1';
  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async => null;
  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {}
  @override
  Future<void> updateRecipe(UpdateRecipeInput input) async {}
}

class _CollectionRepository implements RecipeCollectionRepository {
  _CollectionRepository({this.detail});
  final RecipeCollectionDetailEntity? detail;
  String? createdName;

  @override
  Stream<List<RecipeCollectionEntity>> watchCollections() =>
      Stream.value(detail == null ? const [] : [detail!.collection]);
  @override
  Future<String> createCollection({
    required String name,
    Uint8List? coverBytes,
  }) async {
    createdName = name;
    return 'collection-1';
  }

  @override
  Future<RecipeCollectionDetailEntity?> getCollectionDetail(
    String collectionId,
  ) async => detail;
  @override
  Future<Set<String>> getCollectionIdsForRecipe(String recipeId) async => {};
  @override
  Future<void> deleteCollection(String collectionId) async {}
  @override
  Future<void> updateCollection({
    required String collectionId,
    required String name,
    required RecipeCollectionCoverChange coverChange,
  }) async {}
  @override
  Future<void> setCollectionsForRecipe({
    required String recipeId,
    required Set<String> collectionIds,
  }) async {}
  @override
  Future<void> appendRecipesToCollection({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) async {}
  @override
  Future<int> removeRecipeFromCollection({
    required String collectionId,
    required String recipeId,
  }) async => 0;
  @override
  Future<void> restoreRecipeToCollection({
    required String collectionId,
    required String recipeId,
    required int position,
  }) async {}
  @override
  Future<void> reorderCollectionMembers({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) async {}
}

class _DeletionRepository implements RecipeDeletionRepository {
  String? restoredId;
  String? movedId;
  @override
  Future<void> moveToTrash(String recipeId) async => movedId = recipeId;
  @override
  Future<void> permanentlyDeleteRecipe(String recipeId) async {}
  @override
  Future<int> purgeDeletedBefore(DateTime cutoff) async => 0;
  @override
  Future<void> restoreRecipe(String recipeId) async => restoredId = recipeId;
}
