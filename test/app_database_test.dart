import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_notes/src/data/app_database.dart';

void main() {
  test('数据库首次打开会创建示例菜谱及结构化详情', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final recipes = await database.watchRecipes().first;
    expect(recipes, hasLength(3));

    final detail = await database.getRecipeDetail('sample-tomato-eggs');
    expect(detail, isNotNull);
    expect(detail!.ingredients, hasLength(4));
    expect(detail.steps, hasLength(3));
    expect(detail.tags, contains('快手'));
  });

  test('菜谱搜索支持食材名称', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final results = await database.watchRecipes(query: '鸡蛋').first;
    expect(results.map((recipe) => recipe.title), contains('番茄炒蛋'));
  });
}
