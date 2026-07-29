import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/kitchen_recipe_data_app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

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

  test('schema v1 菜谱迁移后获得默认模板标识和版本', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kitchen_notes_migration_',
    );
    final file = File('${directory.path}/v1.sqlite');
    final raw = sqlite.sqlite3.open(file.path);
    raw
      ..execute('''
        CREATE TABLE recipes (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          summary TEXT NOT NULL DEFAULT '',
          category TEXT NOT NULL DEFAULT '家常菜',
          servings INTEGER,
          prep_minutes INTEGER,
          cook_minutes INTEGER,
          difficulty TEXT NOT NULL DEFAULT '简单',
          presentation_style TEXT NOT NULL DEFAULT 'inheritDefault',
          is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1)),
          last_cooked_at INTEGER,
          cook_count INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'ready',
          cover_color INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute(
        '''
        INSERT INTO recipes (
          id, title, cover_color, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        ['legacy-recipe', '旧菜谱', 0xFFF4B9A8, 0, 0],
      )
      ..execute('PRAGMA user_version = 1')
      ..close();

    final database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final recipe = await (database.select(
        database.recipes,
      )..where((row) => row.id.equals('legacy-recipe'))).getSingle();

      expect(recipe.templateId, 'builtin.journal.basic');
      expect(recipe.templateVersion, 1);
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 2);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
