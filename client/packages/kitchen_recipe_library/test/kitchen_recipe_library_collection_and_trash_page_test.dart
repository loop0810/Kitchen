import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
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

  testWidgets('空菜谱集单击进入成员管理，长按仍显示管理菜单', (tester) async {
    final collections = _CollectionRepository(detail: _emptyCollectionDetail);
    await tester.pumpWidget(_app(collections: collections, routed: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜谱集'));
    await tester.pumpAndSettle();

    final book = find.byKey(const ValueKey('collection-1'));
    await tester.ensureVisible(book);
    await tester.longPress(book);
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('管理成员'), findsOneWidget);
    expect(find.text('删除菜谱集'), findsOneWidget);
    final actionImages = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .toList();
    expect(actionImages, hasLength(3));
    expect(
      actionImages.map((image) => image.assetName),
      containsAll([
        'assets/images/recipe_collection_action_edit.png',
        'assets/images/recipe_collection_action_manage.png',
        'assets/images/recipe_collection_action_delete.png',
      ]),
    );
    expect(
      actionImages.every((image) => image.package == 'kitchen_recipe_library'),
      isTrue,
    );
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.tap(book);
    await tester.pumpAndSettle();
    expect(find.text('成员管理页'), findsOneWidget);
  });

  testWidgets('菜谱集删除弹窗在嵌套导航中取消不会弹出最后一页', (tester) async {
    final collections = _CollectionRepository(detail: _emptyCollectionDetail);
    await tester.pumpWidget(
      _app(collections: collections, nestedNavigator: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜谱集'));
    await tester.pumpAndSettle();

    final book = find.byKey(const ValueKey('collection-1'));
    await tester.longPress(book);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除菜谱集'));
    await tester.pumpAndSettle();
    expect(find.text('确定删除这个菜谱集？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('确定删除这个菜谱集？'), findsNothing);
    expect(find.byKey(const ValueKey('collection-1')), findsOneWidget);
  });

  testWidgets('菜谱集删除弹窗在嵌套导航中确认只删除菜谱集', (tester) async {
    final collections = _CollectionRepository(detail: _emptyCollectionDetail);
    await tester.pumpWidget(
      _app(collections: collections, nestedNavigator: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜谱集'));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('collection-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除菜谱集'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(collections.deletedId, 'collection-1');
    expect(find.text('确定删除这个菜谱集？'), findsNothing);
  });

  testWidgets('非空菜谱集单击直接进入阅读器', (tester) async {
    final collections = _CollectionRepository(
      detail: _nonEmptyCollectionDetail,
    );
    await tester.pumpWidget(_app(collections: collections, routed: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜谱集'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('collection-2')));
    await tester.pumpAndSettle();

    expect(find.text('阅读器页'), findsOneWidget);
  });

  testWidgets('阅读器显示固定页数并可左右翻阅', (tester) async {
    final collections = _CollectionRepository(
      detail: _nonEmptyCollectionDetail,
    );
    await tester.pumpWidget(
      _app(
        collections: collections,
        page: const RecipeCollectionReaderPage(collectionId: 'collection-2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byTooltip('管理菜谱集成员'), findsNothing);
    expect(
      find.byKey(const ValueKey('recipe-collection-reader-pages')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('recipe-collection-reader-pages')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('从详情返回后保持阅读页码', (tester) async {
    final collections = _CollectionRepository(
      detail: _nonEmptyCollectionDetail,
    );
    await tester.pumpWidget(
      _app(
        collections: collections,
        showActiveRecipe: true,
        routed: true,
        actualReaderRoute: true,
        initialLocation: '/recipe-collections/collection-2/read',
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('recipe-collection-reader-pages')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('周末面包，查看详细步骤'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('详情页'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
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

    await tester.longPress(find.bySemanticsLabel(RegExp('可管理菜谱')));
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
  bool routed = false,
  bool nestedNavigator = false,
  bool actualReaderRoute = false,
  String initialLocation = '/recipes',
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
          deleteCollection: DeleteRecipeCollectionUseCase(collectionRepository),
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
          getCollectionReaderSnapshot: GetRecipeCollectionReaderSnapshotUseCase(
            collectionRepository,
            const _ReadingOrderPolicy(),
          ),
          getRecipeJournalSummary: GetRecipeJournalSummaryUseCase(
            recipeRepository,
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
    child: routed
        ? MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: initialLocation,
              routes: [
                GoRoute(
                  path: '/recipes',
                  name: AppRouteNames.recipes,
                  builder: (_, _) => page,
                ),
                GoRoute(
                  path: '/recipe-collections/:id',
                  name: AppRouteNames.recipeCollection,
                  builder: (_, _) => const Scaffold(body: Text('成员管理页')),
                ),
                GoRoute(
                  path: '/recipe-collections/:id/read',
                  name: AppRouteNames.recipeCollectionReader,
                  builder: (_, state) => actualReaderRoute
                      ? RecipeCollectionReaderPage(
                          collectionId: state.pathParameters['id']!,
                        )
                      : const Scaffold(body: Text('阅读器页')),
                ),
                GoRoute(
                  path: '/recipes/:id',
                  name: AppRouteNames.recipeDetail,
                  builder: (_, _) =>
                      Scaffold(appBar: AppBar(title: const Text('详情页'))),
                ),
              ],
            ),
          )
        : MaterialApp(
            home: nestedNavigator
                ? Navigator(
                    onGenerateRoute: (_) =>
                        MaterialPageRoute(builder: (_) => page),
                  )
                : page,
          ),
  );
}

class _ReadingOrderPolicy implements RecipeReadingOrderPolicy {
  const _ReadingOrderPolicy();

  @override
  int compare(
    RecipeJournalSummaryEntity left,
    RecipeJournalSummaryEntity right,
  ) => left.recipe.title.compareTo(right.recipe.title);

  @override
  String groupLabelFor(String title) => title[0].toUpperCase();
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
final _nonEmptyCollection = RecipeCollectionEntity(
  id: 'collection-2',
  name: '家常菜本',
  memberCount: 2,
  coverBytes: null,
  createdAt: _now,
  updatedAt: _now,
);
final _nonEmptyCollectionDetail = RecipeCollectionDetailEntity(
  collection: _nonEmptyCollection,
  members: [
    RecipeCollectionMemberEntity(
      recipe: _activeSummary,
      addedAt: _now,
      position: 0,
    ),
    RecipeCollectionMemberEntity(
      recipe: _secondActiveSummary,
      addedAt: _now,
      position: 1,
    ),
  ],
);
final _secondActiveSummary = RecipeJournalSummaryEntity(
  recipe: RecipeEntity(
    id: 'second-recipe',
    title: '周末面包',
    summary: '',
    category: '烘焙',
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
    status: RecipeStatus.ready,
    coverColor: 0xFFF4B9A8,
    createdAt: _now,
    updatedAt: _now,
  ),
  primaryIngredients: const [],
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
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async {
    final summary = switch (recipeId) {
      'active-recipe' => _activeSummary,
      'second-recipe' => _secondActiveSummary,
      _ => null,
    };
    if (!showActiveRecipe || summary == null) return null;
    return RecipeDetailEntity(
      recipe: summary.recipe,
      ingredients: const [],
      steps: const [],
      tags: const [],
    );
  }

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
  String? deletedId;

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
  Future<void> deleteCollection(String collectionId) async =>
      deletedId = collectionId;
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
