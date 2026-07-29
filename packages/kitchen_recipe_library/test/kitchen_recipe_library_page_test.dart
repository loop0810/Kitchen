import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';

void main() {
  testWidgets('菜谱库等待 Repository Stream 时展示加载状态', (tester) async {
    final controller = StreamController<List<RecipeJournalSummaryEntity>>();
    addTearDown(controller.close);
    final repository = _LibraryRepository(
      streamFactory: (query) => controller.stream,
    );

    await tester.pumpWidget(_testApp(repository, const RecipeLibraryPage()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('菜谱库展示加载、数据与筛选状态', (tester) async {
    final repository = _LibraryRepository(
      streamFactory: (query) => Stream.value([_summary]),
    );
    await tester.pumpWidget(_testApp(repository, const RecipeLibraryPage()));
    await tester.pumpAndSettle();

    expect(find.text('番茄炒蛋'), findsOneWidget);
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(repository.lastQuery?.statusFilter, RecipeStatusFilter.favorite);
  });

  testWidgets('菜谱库展示查询失败状态', (tester) async {
    final repository = _LibraryRepository(
      streamFactory: (query) => Stream.error(StateError('database failed')),
    );
    await tester.pumpWidget(_testApp(repository, const RecipeLibraryPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('菜谱加载失败'), findsOneWidget);
  });

  testWidgets('搜索页传递文本查询并展示结果', (tester) async {
    final repository = _LibraryRepository(
      streamFactory: (query) => Stream.value([_summary]),
    );
    await tester.pumpWidget(
      _testApp(repository, const SearchPage(initialQuery: '番茄')),
    );
    await tester.pumpAndSettle();

    expect(repository.lastQuery?.text, '番茄');
    expect(find.text('番茄炒蛋'), findsOneWidget);
  });

  testWidgets('详情页展示 Domain 详情并委托收藏操作', (tester) async {
    final repository = _LibraryRepository(
      streamFactory: (query) => const Stream.empty(),
      detail: _detail,
    );
    await tester.pumpWidget(
      _testApp(repository, const RecipeDetailPage(recipeId: 'recipe-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('食材'), findsOneWidget);
    expect(find.text('鸡蛋'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('打散鸡蛋'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('打散鸡蛋'), findsOneWidget);

    await tester.tap(find.byTooltip('收藏'));
    await tester.pumpAndSettle();
    expect(repository.favoriteRecipeId, 'recipe-1');
    expect(repository.favoriteValue, isTrue);
    expect(find.byTooltip('编辑菜谱'), findsOneWidget);
  });

  testWidgets('编辑成功返回后详情失效缓存并展示最新数据', (tester) async {
    final repository = _LibraryRepository(
      streamFactory: (query) => const Stream.empty(),
      detail: _detail,
    );
    final router = GoRouter(
      initialLocation: '/recipes/recipe-1',
      routes: [
        GoRoute(
          path: '/recipes/:id/edit',
          name: AppRouteNames.editRecipe,
          builder: (context, state) => Scaffold(
            body: FilledButton(
              onPressed: () {
                repository.detail = _detailWithTitle('更新后的番茄炒蛋');
                context.pop(true);
              },
              child: const Text('完成编辑'),
            ),
          ),
        ),
        GoRoute(
          path: '/recipes/:id',
          name: AppRouteNames.recipeDetail,
          builder: (context, state) =>
              RecipeDetailPage(recipeId: state.pathParameters['id']!),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeLibraryDependenciesProvider.overrideWithValue(
            RecipeLibraryDependencies(
              watchRecipes: WatchRecipesUseCase(repository),
              getRecipeDetail: GetRecipeDetailUseCase(repository),
              setFavorite: SetRecipeFavoriteUseCase(repository),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('编辑菜谱'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成编辑'));
    await tester.pumpAndSettle();

    expect(find.text('更新后的番茄炒蛋'), findsOneWidget);
    expect(repository.detailReadCount, 2);
  });

  testWidgets('详情按保存顺序展示食材且不插入分组标题', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _LibraryRepository(
      streamFactory: (query) => const Stream.empty(),
      detail: _detailWithTwoIngredients,
    );
    await tester.pumpWidget(
      _testApp(repository, const RecipeDetailPage(recipeId: 'recipe-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('鸡蛋'), findsOneWidget);
    expect(find.text('白胡椒'), findsOneWidget);
    expect(find.text('主料'), findsNothing);
    expect(find.text('调料'), findsNothing);
    expect(find.text('其他食材'), findsNothing);
    final ingredientTexts = find
        .byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data == '鸡蛋' || widget.data == '白胡椒'),
        )
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .toList();
    expect(ingredientTexts, ['鸡蛋', '白胡椒']);
  });
}

Widget _testApp(_LibraryRepository repository, Widget page) {
  return ProviderScope(
    overrides: [
      recipeLibraryDependenciesProvider.overrideWithValue(
        RecipeLibraryDependencies(
          watchRecipes: WatchRecipesUseCase(repository),
          getRecipeDetail: GetRecipeDetailUseCase(repository),
          setFavorite: SetRecipeFavoriteUseCase(repository),
        ),
      ),
    ],
    child: MaterialApp(home: page),
  );
}

final _now = DateTime(2026, 7, 27);
final _recipe = RecipeEntity(
  id: 'recipe-1',
  title: '番茄炒蛋',
  summary: '家常快手菜',
  category: '家常菜',
  servings: 2,
  prepMinutes: 5,
  cookMinutes: 10,
  difficulty: '简单',
  presentationStyle: 'inheritDefault',
  templateSelection: _templateSelection,
  isFavorite: false,
  lastCookedAt: null,
  cookCount: 0,
  status: RecipeStatus.ready,
  coverColor: 0xFFF4B9A8,
  createdAt: _now,
  updatedAt: _now,
);
final _summary = RecipeJournalSummaryEntity(
  recipe: _recipe,
  primaryIngredients: const [
    IngredientSummaryValueObject(name: '鸡蛋', amountText: '2 个'),
  ],
);
final _detail = RecipeDetailEntity(
  recipe: _recipe,
  ingredients: const [
    IngredientEntity(
      id: 'ingredient-1',
      recipeId: 'recipe-1',
      name: '鸡蛋',
      amountText: '2 个',
      amountValue: 2,
      unit: '个',
      preparation: null,
      isOptional: false,
      position: 0,
    ),
  ],
  steps: const [
    RecipeStepEntity(
      id: 'step-1',
      recipeId: 'recipe-1',
      position: 0,
      title: null,
      instruction: '打散鸡蛋',
      durationMinutes: null,
      heatLevel: null,
    ),
  ],
  tags: const ['快手'],
);
final _detailWithTwoIngredients = RecipeDetailEntity(
  recipe: _recipe,
  ingredients: const [
    IngredientEntity(
      id: 'ingredient-1',
      recipeId: 'recipe-1',
      name: '鸡蛋',
      amountText: '2 个',
      amountValue: 2,
      unit: '个',
      preparation: null,
      isOptional: false,
      position: 0,
    ),
    IngredientEntity(
      id: 'ingredient-2',
      recipeId: 'recipe-1',
      name: '白胡椒',
      amountText: '少许',
      amountValue: null,
      unit: null,
      preparation: null,
      isOptional: false,
      position: 1,
    ),
  ],
  steps: _detail.steps,
  tags: _detail.tags,
);

RecipeDetailEntity _detailWithTitle(String title) {
  return RecipeDetailEntity(
    recipe: RecipeEntity(
      id: _recipe.id,
      title: title,
      summary: _recipe.summary,
      category: _recipe.category,
      servings: _recipe.servings,
      prepMinutes: _recipe.prepMinutes,
      cookMinutes: _recipe.cookMinutes,
      difficulty: _recipe.difficulty,
      presentationStyle: _recipe.presentationStyle,
      templateSelection: _recipe.templateSelection,
      isFavorite: _recipe.isFavorite,
      lastCookedAt: _recipe.lastCookedAt,
      cookCount: _recipe.cookCount,
      status: _recipe.status,
      coverColor: _recipe.coverColor,
      createdAt: _recipe.createdAt,
      updatedAt: _recipe.updatedAt,
    ),
    ingredients: _detail.ingredients,
    steps: _detail.steps,
    tags: _detail.tags,
  );
}

class _LibraryRepository implements RecipeRepository {
  _LibraryRepository({required this.streamFactory, this.detail});

  final Stream<List<RecipeJournalSummaryEntity>> Function(RecipeQuery query)
  streamFactory;
  RecipeDetailEntity? detail;
  int detailReadCount = 0;
  RecipeQuery? lastQuery;
  String? favoriteRecipeId;
  bool? favoriteValue;

  @override
  Future<String> createRecipe(CreateRecipeInput input) async => 'recipe-1';

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async {
    detailReadCount += 1;
    return detail;
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
  Future<void> updateRecipe(UpdateRecipeInput input) async {}

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    lastQuery = query;
    return streamFactory(query);
  }
}

const _templateSelection = RecipeTemplateSelectionValueObject(
  templateId: 'builtin.journal.basic',
  templateVersion: 1,
);
