import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/database/kitchen_recipe_data_app_database.dart';
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

  test('schema v1 菜谱迁移后获得模板字段并移除食材分组', () async {
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
      ..execute('''
        CREATE TABLE ingredient_groups (
          id TEXT NOT NULL PRIMARY KEY,
          recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
          name TEXT NOT NULL,
          position INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE ingredients (
          id TEXT NOT NULL PRIMARY KEY,
          recipe_id TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
          group_id TEXT REFERENCES ingredient_groups(id) ON DELETE SET NULL,
          name TEXT NOT NULL,
          amount_text TEXT NOT NULL DEFAULT '适量',
          amount_value REAL,
          unit TEXT,
          preparation TEXT,
          is_optional INTEGER NOT NULL DEFAULT 0 CHECK (is_optional IN (0, 1)),
          position INTEGER NOT NULL
        )
      ''')
      ..execute(
        '''
        INSERT INTO recipes (
          id, title, status, cover_color, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        ['legacy-recipe', '旧菜谱', 'deleted', 0xFFF4B9A8, 0, 0],
      )
      ..execute(
        '''
        INSERT INTO ingredient_groups (id, recipe_id, name, position)
        VALUES (?, ?, ?, ?)
        ''',
        ['legacy-group', 'legacy-recipe', '主料', 0],
      )
      ..execute(
        '''
        INSERT INTO ingredients (
          id, recipe_id, group_id, name, amount_text, position
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        ['legacy-ingredient', 'legacy-recipe', 'legacy-group', '鸡蛋', '2 个', 0],
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
      expect(version.read<int>('user_version'), 6);
      expect(recipe.importTaskId, isNull);
      expect(recipe.sourceOriginalText, isNull);
      expect(recipe.deletedAt, isNotNull);
      expect(recipe.statusBeforeDeletion, isNull);
      expect(await database.select(database.recipeCollections).get(), isEmpty);
      final columns = await database
          .customSelect('PRAGMA table_info(ingredients)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')),
        isNot(contains('group_id')),
      );
      final groupTable = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'ingredient_groups'",
          )
          .get();
      expect(groupTable, isEmpty);
      final ingredient = await (database.select(
        database.ingredients,
      )..where((row) => row.id.equals('legacy-ingredient'))).getSingle();
      expect(ingredient.name, '鸡蛋');
      expect(ingredient.position, 0);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });

  test('schema v5 迁移按旧视觉顺序生成连续成员位置', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kitchen_notes_v5_migration_',
    );
    final file = File('${directory.path}/v5.sqlite');
    final raw = sqlite.sqlite3.open(file.path);
    raw
      ..execute('''
        CREATE TABLE recipe_collections (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          position INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('''
        CREATE TABLE recipe_collection_members (
          collection_id TEXT NOT NULL,
          recipe_id TEXT NOT NULL,
          added_at INTEGER NOT NULL,
          PRIMARY KEY (collection_id, recipe_id)
        )
      ''')
      ..execute('INSERT INTO recipe_collections VALUES (?, ?, ?, ?, ?)', [
        'collection-1',
        '旧集合',
        0,
        0,
        0,
      ])
      ..execute('INSERT INTO recipe_collection_members VALUES (?, ?, ?)', [
        'collection-1',
        'recipe-b',
        200,
      ])
      ..execute('INSERT INTO recipe_collection_members VALUES (?, ?, ?)', [
        'collection-1',
        'recipe-a',
        200,
      ])
      ..execute('INSERT INTO recipe_collection_members VALUES (?, ?, ?)', [
        'collection-1',
        'recipe-newest',
        300,
      ])
      ..execute('PRAGMA user_version = 5')
      ..close();

    final database = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final members = await database
          .customSelect(
            'SELECT recipe_id, position FROM recipe_collection_members '
            'ORDER BY position ASC',
          )
          .get();
      expect(members.map((row) => row.read<String>('recipe_id')), [
        'recipe-newest',
        'recipe-a',
        'recipe-b',
      ]);
      expect(members.map((row) => row.read<int>('position')), [0, 1, 2]);
      final coverPathColumn = await database
          .customSelect(
            "SELECT name FROM pragma_table_info('recipe_collections') "
            "WHERE name = 'cover_path'",
          )
          .getSingleOrNull();
      expect(coverPathColumn, isNotNull);
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
