import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'package:kitchen_recipe_data/src/recipe/policies/kitchen_recipe_data_pinyin_recipe_reading_order_policy.dart';

void main() {
  const policy = PinyinRecipeReadingOrderPolicy();

  test('中文、英文和数字符号按阅读规则稳定排序', () {
    final recipes = [
      _summary('7', '🍳 123 汤'),
      _summary('6', 'apple pie'),
      _summary('5', 'Bread'),
      _summary('4', '重庆小面'),
      _summary('3', '阿胶糕'),
      _summary('2', '番茄炒蛋'),
      _summary('1', '【包子】'),
    ]..sort(policy.compare);

    expect(recipes.map((item) => item.recipe.title), [
      '【包子】',
      '重庆小面',
      '阿胶糕',
      '番茄炒蛋',
      'apple pie',
      'Bread',
      '🍳 123 汤',
    ]);
    expect(policy.groupLabelFor('【番茄炒蛋】'), 'F');
    expect(policy.groupLabelFor('🍳 Bread'), 'B');
    expect(policy.groupLabelFor('123 汤'), '#');
  });

  test('同标题最终按菜谱 ID 排序', () {
    final recipes = [_summary('b', '面包'), _summary('a', '面包')]
      ..sort(policy.compare);
    expect(recipes.map((item) => item.recipe.id), ['a', 'b']);
  });
}

RecipeJournalSummaryEntity _summary(String id, String title) {
  final now = DateTime(2026, 8, 1);
  return RecipeJournalSummaryEntity(
    recipe: RecipeEntity(
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
      lastCookedAt: null,
      cookCount: 0,
      status: RecipeStatus.ready,
      coverColor: 0xFFF4B9A8,
      createdAt: now,
      updatedAt: now,
    ),
    primaryIngredients: const [],
  );
}
