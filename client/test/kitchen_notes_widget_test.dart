import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_notes/main.dart';
import 'package:kitchen_notes/src/kitchen_notes_app.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  testWidgets('App 完成依赖装配并展示四栏核心流程', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: buildRecipeFeatureOverrides(_AppRepository()),
        child: const KitchenNotesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今天想吃点什么？'), findsOneWidget);
    expect(find.text('创建菜谱'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('菜谱库'), findsOneWidget);
    expect(find.text('导入箱'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('菜谱库'));
    await tester.pumpAndSettle();
    expect(find.text('装配测试菜谱'), findsOneWidget);
  });
}

class _AppRepository implements RecipeRepository {
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

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    final now = DateTime(2026, 7, 27);
    return Stream.value([
      RecipeJournalSummaryEntity(
        recipe: RecipeEntity(
          id: 'recipe-1',
          title: '装配测试菜谱',
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
          createdAt: now,
          updatedAt: now,
        ),
        primaryIngredients: const [],
      ),
    ]);
  }
}
