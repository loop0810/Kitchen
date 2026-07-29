import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'kitchen_recipe_data_app_database.g.dart';

class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('家常菜'))();
  IntColumn get servings => integer().nullable()();
  IntColumn get prepMinutes => integer().nullable()();
  IntColumn get cookMinutes => integer().nullable()();
  TextColumn get difficulty => text().withDefault(const Constant('简单'))();
  TextColumn get presentationStyle =>
      text().withDefault(const Constant('inheritDefault'))();
  TextColumn get templateId =>
      text().withDefault(const Constant('builtin.journal.basic'))();
  IntColumn get templateVersion => integer().withDefault(const Constant(1))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastCookedAt => dateTime().nullable()();
  IntColumn get cookCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('ready'))();
  IntColumn get coverColor => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class IngredientGroups extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get groupId => text().nullable().references(
    IngredientGroups,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text()();
  TextColumn get amountText => text().withDefault(const Constant('适量'))();
  RealColumn get amountValue => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get preparation => text().nullable()();
  BoolColumn get isOptional => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RecipeSteps extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get instruction => text()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get heatLevel => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class RecipeTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {recipeId, tag},
  ];
}

class RecipeDetailData {
  const RecipeDetailData({
    required this.recipe,
    required this.groups,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });

  final Recipe recipe;
  final List<IngredientGroup> groups;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> tags;
}

class RecipeSummaryData {
  const RecipeSummaryData({
    required this.recipe,
    required this.groups,
    required this.ingredients,
  });

  final Recipe recipe;
  final List<IngredientGroup> groups;
  final List<Ingredient> ingredients;
}

@DriftDatabase(
  tables: [Recipes, IngredientGroups, Ingredients, RecipeSteps, RecipeTags],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedExampleRecipes();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(recipes, recipes.templateId);
        await migrator.addColumn(recipes, recipes.templateVersion);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<Recipe>> watchRecipes({
    String query = '',
    String statusFilter = 'all',
  }) {
    final statement = select(recipes);
    final normalized = query.trim();
    if (normalized.isNotEmpty) {
      final pattern = '%$normalized%';
      statement.where(
        (recipe) =>
            recipe.title.like(pattern) |
            recipe.summary.like(pattern) |
            recipe.category.like(pattern) |
            existsQuery(
              select(ingredients)..where(
                (ingredient) =>
                    ingredient.recipeId.equalsExp(recipe.id) &
                    ingredient.name.like(pattern),
              ),
            ) |
            existsQuery(
              select(recipeTags)..where(
                (tag) =>
                    tag.recipeId.equalsExp(recipe.id) & tag.tag.like(pattern),
              ),
            ),
      );
    }
    if (statusFilter == 'favorite') {
      statement.where((recipe) => recipe.isFavorite.equals(true));
    } else if (statusFilter == 'cooked') {
      statement.where((recipe) => recipe.cookCount.isBiggerThanValue(0));
    } else if (statusFilter == 'incomplete') {
      statement.where((recipe) => recipe.status.equals('incomplete'));
    }
    statement.orderBy([(recipe) => OrderingTerm.desc(recipe.updatedAt)]);
    return statement.watch();
  }

  Stream<List<RecipeSummaryData>> watchRecipeSummaries({
    String query = '',
    String statusFilter = 'all',
  }) {
    final statement = select(recipes).join([
      leftOuterJoin(ingredients, ingredients.recipeId.equalsExp(recipes.id)),
      leftOuterJoin(
        ingredientGroups,
        ingredientGroups.id.equalsExp(ingredients.groupId),
      ),
    ]);
    final normalized = query.trim();
    if (normalized.isNotEmpty) {
      final pattern = '%$normalized%';
      statement.where(
        recipes.title.like(pattern) |
            recipes.summary.like(pattern) |
            recipes.category.like(pattern) |
            existsQuery(
              select(ingredients)..where(
                (ingredient) =>
                    ingredient.recipeId.equalsExp(recipes.id) &
                    ingredient.name.like(pattern),
              ),
            ) |
            existsQuery(
              select(recipeTags)..where(
                (tag) =>
                    tag.recipeId.equalsExp(recipes.id) & tag.tag.like(pattern),
              ),
            ),
      );
    }
    if (statusFilter == 'favorite') {
      statement.where(recipes.isFavorite.equals(true));
    } else if (statusFilter == 'cooked') {
      statement.where(recipes.cookCount.isBiggerThanValue(0));
    } else if (statusFilter == 'incomplete') {
      statement.where(recipes.status.equals('incomplete'));
    }
    statement.orderBy([
      OrderingTerm.desc(recipes.updatedAt),
      OrderingTerm.asc(ingredients.position),
    ]);

    return statement.watch().map((rows) {
      final summaries = <String, _MutableRecipeSummary>{};
      for (final row in rows) {
        final recipe = row.readTable(recipes);
        final summary = summaries.putIfAbsent(
          recipe.id,
          () => _MutableRecipeSummary(recipe),
        );
        final ingredient = row.readTableOrNull(ingredients);
        if (ingredient != null) {
          summary.ingredients.add(ingredient);
        }
        final group = row.readTableOrNull(ingredientGroups);
        if (group != null) {
          summary.groups[group.id] = group;
        }
      }
      return summaries.values
          .map(
            (summary) => RecipeSummaryData(
              recipe: summary.recipe,
              groups: summary.groups.values.toList(growable: false),
              ingredients: summary.ingredients,
            ),
          )
          .toList(growable: false);
    });
  }

  Future<RecipeDetailData?> getRecipeDetail(String id) async {
    final recipe = await (select(
      recipes,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (recipe == null) return null;

    final groupRows =
        await (select(ingredientGroups)
              ..where((row) => row.recipeId.equals(id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    final ingredientRows =
        await (select(ingredients)
              ..where((row) => row.recipeId.equals(id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    final stepRows =
        await (select(recipeSteps)
              ..where((row) => row.recipeId.equals(id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();
    final tagRows = await (select(
      recipeTags,
    )..where((row) => row.recipeId.equals(id))).get();

    return RecipeDetailData(
      recipe: recipe,
      groups: groupRows,
      ingredients: ingredientRows,
      steps: stepRows,
      tags: tagRows.map((row) => row.tag).toList(),
    );
  }

  Future<void> setFavorite(String id, {required bool value}) {
    return (update(recipes)..where((row) => row.id.equals(id))).write(
      RecipesCompanion(
        isFavorite: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _seedExampleRecipes() async {
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(recipes, [
        RecipesCompanion.insert(
          id: 'sample-tomato-eggs',
          title: '番茄炒蛋',
          summary: const Value('酸甜开胃、十几分钟就能完成的家常菜。'),
          category: const Value('家常菜'),
          servings: const Value(2),
          prepMinutes: const Value(5),
          cookMinutes: const Value(10),
          difficulty: const Value('简单'),
          coverColor: 0xFFF4B9A8,
          createdAt: now,
          updatedAt: now,
        ),
        RecipesCompanion.insert(
          id: 'sample-chicken-wings',
          title: '红烧鸡翅',
          summary: const Value('咸甜浓郁，适合作为周末晚餐。'),
          category: const Value('家常菜'),
          servings: const Value(3),
          prepMinutes: const Value(15),
          cookMinutes: const Value(30),
          difficulty: const Value('中等'),
          isFavorite: const Value(true),
          lastCookedAt: Value(now.subtract(const Duration(days: 3))),
          cookCount: const Value(2),
          coverColor: 0xFFD9A06F,
          createdAt: now.subtract(const Duration(minutes: 2)),
          updatedAt: now.subtract(const Duration(minutes: 2)),
        ),
        RecipesCompanion.insert(
          id: 'sample-pumpkin-soup',
          title: '奶油南瓜汤',
          summary: const Value('温暖顺滑，适合秋冬的一人食。'),
          category: const Value('汤羹'),
          servings: const Value(2),
          prepMinutes: const Value(10),
          cookMinutes: const Value(25),
          difficulty: const Value('简单'),
          status: const Value('incomplete'),
          coverColor: 0xFFF1CA7B,
          createdAt: now.subtract(const Duration(minutes: 4)),
          updatedAt: now.subtract(const Duration(minutes: 4)),
        ),
      ]);

      batch.insertAll(ingredientGroups, const [
        IngredientGroupsCompanion(
          id: Value('g-tomato-main'),
          recipeId: Value('sample-tomato-eggs'),
          name: Value('主料'),
          position: Value(0),
        ),
        IngredientGroupsCompanion(
          id: Value('g-tomato-seasoning'),
          recipeId: Value('sample-tomato-eggs'),
          name: Value('调料'),
          position: Value(1),
        ),
      ]);

      batch.insertAll(ingredients, const [
        IngredientsCompanion(
          id: Value('i-tomato'),
          recipeId: Value('sample-tomato-eggs'),
          groupId: Value('g-tomato-main'),
          name: Value('番茄'),
          amountText: Value('2 个'),
          amountValue: Value(2),
          unit: Value('个'),
          preparation: Value('切块'),
          position: Value(0),
        ),
        IngredientsCompanion(
          id: Value('i-eggs'),
          recipeId: Value('sample-tomato-eggs'),
          groupId: Value('g-tomato-main'),
          name: Value('鸡蛋'),
          amountText: Value('3 个'),
          amountValue: Value(3),
          unit: Value('个'),
          preparation: Value('打散'),
          position: Value(1),
        ),
        IngredientsCompanion(
          id: Value('i-salt'),
          recipeId: Value('sample-tomato-eggs'),
          groupId: Value('g-tomato-seasoning'),
          name: Value('盐'),
          amountText: Value('适量'),
          position: Value(2),
        ),
        IngredientsCompanion(
          id: Value('i-oil'),
          recipeId: Value('sample-tomato-eggs'),
          groupId: Value('g-tomato-seasoning'),
          name: Value('食用油'),
          amountText: Value('15 ml'),
          amountValue: Value(15),
          unit: Value('ml'),
          position: Value(3),
        ),
      ]);

      batch.insertAll(recipeSteps, const [
        RecipeStepsCompanion(
          id: Value('s-tomato-1'),
          recipeId: Value('sample-tomato-eggs'),
          position: Value(0),
          title: Value('处理食材'),
          instruction: Value('番茄切块，鸡蛋加少许盐后充分打散。'),
        ),
        RecipeStepsCompanion(
          id: Value('s-tomato-2'),
          recipeId: Value('sample-tomato-eggs'),
          position: Value(1),
          title: Value('炒鸡蛋'),
          instruction: Value('锅中放一半食用油，中火将鸡蛋炒至刚刚凝固后盛出。'),
          durationMinutes: Value(1),
          heatLevel: Value('中火'),
        ),
        RecipeStepsCompanion(
          id: Value('s-tomato-3'),
          recipeId: Value('sample-tomato-eggs'),
          position: Value(2),
          title: Value('混合翻炒'),
          instruction: Value('加入剩余油和番茄，炒软出汁后放回鸡蛋，调味并翻炒均匀。'),
          durationMinutes: Value(4),
          heatLevel: Value('中火'),
        ),
      ]);

      batch.insertAll(recipeTags, const [
        RecipeTagsCompanion(
          recipeId: Value('sample-tomato-eggs'),
          tag: Value('快手'),
        ),
        RecipeTagsCompanion(
          recipeId: Value('sample-tomato-eggs'),
          tag: Value('下饭'),
        ),
        RecipeTagsCompanion(
          recipeId: Value('sample-chicken-wings'),
          tag: Value('周末'),
        ),
      ]);
    });
  }
}

class _MutableRecipeSummary {
  _MutableRecipeSummary(this.recipe);

  final Recipe recipe;
  final Map<String, IngredientGroup> groups = {};
  final List<Ingredient> ingredients = [];
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'kitchen_notes.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
