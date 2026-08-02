import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';

void main() {
  testWidgets('编辑页加载现有字段并保存稳定 ID 与隐藏元数据', (tester) async {
    final repository = _EditRepository(detail: _detail);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await _openEditor(tester);

    final fields = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(fields.at(0)).controller?.text, '番茄炒蛋');
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller?.text,
      contains('鸡蛋  2 个'),
    );
    await tester.enterText(fields.at(0), '嫩滑炒蛋');
    await tester.enterText(fields.at(2), '土鸡蛋  3 个\n白胡椒  少许');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final input = repository.updatedInput;
    expect(input?.title, '嫩滑炒蛋');
    expect(input?.ingredients.first.id, 'ingredient-1');
    expect(input?.ingredients.first.preparation, '打散');
    expect(input?.ingredients.first.unit, '个');
    expect(input?.ingredients.last.id, isNull);
    expect(find.text('来源页'), findsOneWidget);
  });

  testWidgets('编辑校验失败时保留输入并展示字段错误', (tester) async {
    final repository = _EditRepository(detail: _detail);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await _openEditor(tester);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.text('请输入菜名'), findsWidgets);
    expect(repository.updatedInput, isNull);
    expect(find.text('编辑菜谱'), findsOneWidget);
  });

  testWidgets('删除旧食材后新增不同食材会保留正确 ID 与输入顺序', (tester) async {
    final repository = _EditRepository(detail: _detailWithTwoIngredients);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await _openEditor(tester);

    final ingredientsField = find.byType(TextFormField).at(2);
    await tester.enterText(ingredientsField, '鸡蛋  2 个');
    await tester.pump();
    await tester.enterText(ingredientsField, '鸡蛋  2 个\n白胡椒  少许');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final ingredients = repository.updatedInput!.ingredients;
    expect(ingredients.map((item) => item.name), ['鸡蛋', '白胡椒']);
    expect(ingredients.first.id, 'ingredient-1');
    expect(ingredients.last.id, isNull);
  });

  testWidgets('更新失败时保留当前输入并显示中文提示', (tester) async {
    final repository = _EditRepository(detail: _detail, failUpdate: true);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await _openEditor(tester);

    await tester.enterText(find.byType(TextFormField).first, '仍需保留');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('更新失败，请稍后重试'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      '仍需保留',
    );
    expect(find.text('编辑菜谱'), findsOneWidget);
  });

  testWidgets('菜谱不存在时展示明确空状态', (tester) async {
    await tester.pumpWidget(_testApp(_EditRepository(detail: null)));
    await tester.pumpAndSettle();
    await _openEditor(tester);

    expect(find.text('菜谱不存在或已被删除'), findsOneWidget);
  });

  testWidgets('存在未保存修改时返回需确认放弃', (tester) async {
    final repository = _EditRepository(detail: _detail);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();
    await _openEditor(tester);

    await tester.enterText(find.byType(TextFormField).first, '未保存标题');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('编辑菜谱'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('放弃修改'));
    await tester.pumpAndSettle();
    expect(find.text('来源页'), findsOneWidget);
  });
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.text('打开编辑页'));
  await tester.pumpAndSettle();
}

Widget _testApp(_EditRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('来源页'),
                FilledButton(
                  onPressed: () => context.push('/recipes/recipe-1/edit'),
                  child: const Text('打开编辑页'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/recipes/:id/edit',
        builder: (context, state) =>
            EditRecipePage(recipeId: state.pathParameters['id']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeEditorDependenciesProvider.overrideWithValue(
        RecipeEditorDependencies(
          createRecipe: CreateRecipeUseCase(repository),
          getRecipeDetail: GetRecipeDetailUseCase(repository),
          updateRecipe: UpdateRecipeUseCase(repository),
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

final _now = DateTime(2026, 7, 29);
final _detail = RecipeDetailEntity(
  recipe: RecipeEntity(
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
    isFavorite: true,
    status: RecipeStatus.ready,
    coverColor: 0xFFF4B9A8,
    createdAt: _now,
    updatedAt: _now,
  ),
  ingredients: const [
    IngredientEntity(
      id: 'ingredient-1',
      recipeId: 'recipe-1',
      name: '鸡蛋',
      amountText: '2 个',
      amountValue: 2,
      unit: '个',
      preparation: '打散',
      isOptional: false,
      position: 0,
    ),
  ],
  steps: const [
    RecipeStepEntity(
      id: 'step-1',
      recipeId: 'recipe-1',
      position: 0,
      title: '准备',
      instruction: '打散鸡蛋',
      durationMinutes: 1,
      heatLevel: null,
    ),
  ],
  tags: const ['快手'],
);
final _detailWithTwoIngredients = RecipeDetailEntity(
  recipe: _detail.recipe,
  ingredients: [
    ..._detail.ingredients,
    const IngredientEntity(
      id: 'ingredient-2',
      recipeId: 'recipe-1',
      name: '番茄',
      amountText: '1 个',
      amountValue: 1,
      unit: '个',
      preparation: '切块',
      isOptional: false,
      position: 1,
    ),
  ],
  steps: _detail.steps,
  tags: _detail.tags,
);

class _EditRepository implements RecipeRepository {
  _EditRepository({required this.detail, this.failUpdate = false});

  final RecipeDetailEntity? detail;
  final bool failUpdate;
  UpdateRecipeInput? updatedInput;

  @override
  Future<String> createRecipe(CreateRecipeInput input) async => 'recipe-1';

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async => detail;

  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {}

  @override
  Future<void> updateRecipe(UpdateRecipeInput input) async {
    updatedInput = input;
    if (failUpdate) throw StateError('failed');
  }

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    return const Stream.empty();
  }
}

const _templateSelection = RecipeTemplateSelectionValueObject(
  templateId: 'builtin.journal.basic',
  templateVersion: 1,
);
