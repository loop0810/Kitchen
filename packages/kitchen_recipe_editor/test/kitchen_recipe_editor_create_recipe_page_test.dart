import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';

void main() {
  testWidgets('缺少菜名时阻止保存', (tester) async {
    final repository = _EditorRepository();
    await tester.pumpWidget(_testApp(repository));

    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(find.text('请输入菜名'), findsOneWidget);
    expect(repository.createdInput, isNull);
  });

  testWidgets('保存成功后进入新菜谱详情', (tester) async {
    final repository = _EditorRepository();
    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(find.byType(TextFormField).first, '测试菜谱');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repository.createdInput?.title, '测试菜谱');
    expect(repository.createdInput?.ingredients, isEmpty);
    expect(repository.createdInput?.steps, isEmpty);
    expect(find.text('详情 recipe-created'), findsOneWidget);
  });

  testWidgets('保存失败时展示明确反馈并保留编辑页', (tester) async {
    final repository = _EditorRepository(shouldFail: true);
    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(find.byType(TextFormField).first, '测试菜谱');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('保存失败，请稍后重试'), findsOneWidget);
    expect(find.text('创建菜谱'), findsOneWidget);
  });
}

Widget _testApp(_EditorRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const CreateRecipePage()),
      GoRoute(
        path: '/recipes/:id',
        name: 'recipeDetail',
        builder: (context, state) => Text('详情 ${state.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeEditorDependenciesProvider.overrideWithValue(
        RecipeEditorDependencies(createRecipe: CreateRecipeUseCase(repository)),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _EditorRepository implements RecipeRepository {
  _EditorRepository({this.shouldFail = false});

  final bool shouldFail;
  CreateRecipeInput? createdInput;

  @override
  Future<String> createRecipe(CreateRecipeInput input) async {
    createdInput = input;
    if (shouldFail) throw StateError('failed');
    return 'recipe-created';
  }

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async => null;

  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {}

  @override
  Stream<List<RecipeEntity>> watchRecipes(RecipeQuery query) {
    return Stream.value(const []);
  }
}
