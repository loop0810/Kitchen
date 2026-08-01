import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_library/src/kitchen_recipe_library_recipe_card_widget.dart';

void main() {
  testWidgets('菜谱卡片使用 Domain Entity 保持展示和回调行为', (tester) async {
    var tapped = false;
    var favoriteTapped = false;
    Offset? longPressPosition;
    final now = DateTime(2026, 7, 26);
    final recipe = RecipeEntity(
      id: 'recipe-1',
      title: '测试菜谱',
      summary: '',
      category: '家常菜',
      servings: 2,
      prepMinutes: 5,
      cookMinutes: 10,
      difficulty: '简单',
      presentationStyle: 'inheritDefault',
      templateSelection: const RecipeTemplateSelectionValueObject(
        templateId: 'builtin.journal.basic',
        templateVersion: 1,
      ),
      isFavorite: true,
      lastCookedAt: null,
      cookCount: 0,
      status: RecipeStatus.incomplete,
      coverColor: 0xFFF4B9A8,
      createdAt: now,
      updatedAt: now,
    );

    final summary = RecipeJournalSummaryEntity(
      recipe: recipe,
      primaryIngredients: const [
        IngredientSummaryValueObject(name: '鸡蛋', amountText: '2 个'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 320,
            child: RecipeCardWidget(
              recipe: summary,
              onTap: () => tapped = true,
              onFavorite: () => favoriteTapped = true,
              onLongPress: (position) => longPressPosition = position,
            ),
          ),
        ),
      ),
    );

    expect(find.text('测试菜谱'), findsOneWidget);
    expect(find.text('鸡蛋'), findsOneWidget);
    expect(find.text('2 个'), findsOneWidget);
    expect(find.text('待完善'), findsOneWidget);
    expect(find.byTooltip('取消收藏'), findsOneWidget);

    await tester.tap(find.byTooltip('取消收藏'));
    expect(favoriteTapped, isTrue);

    await tester.tap(find.text('测试菜谱'));
    expect(tapped, isTrue);

    await tester.longPress(find.text('测试菜谱'));
    expect(longPressPosition, isNotNull);
  });
}
