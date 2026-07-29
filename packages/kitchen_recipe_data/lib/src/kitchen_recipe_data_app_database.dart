import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'kitchen_recipe_data_app_database.g.dart';

/// 菜谱主表：保存列表和详情都需要的基础字段。
///
/// 食材、步骤和标签拆到子表，避免把可重复数据序列化进一个大字段，也便于本地搜索。
class Recipes extends Table {
  /// 菜谱主键，由 Repository 生成 UUID。
  TextColumn get id => text()();

  /// 菜谱名称，数据库限制为 1～120 个字符。
  TextColumn get title => text().withLength(min: 1, max: 120)();

  /// 菜谱简介；未填写时保存为空字符串。
  TextColumn get summary => text().withDefault(const Constant(''))();

  /// 唯一主分类；未指定时使用“家常菜”。
  TextColumn get category => text().withDefault(const Constant('家常菜'))();

  /// 适用人数；尚未填写时为空。
  IntColumn get servings => integer().nullable()();

  /// 食材准备时间，单位为分钟；尚未填写时为空。
  IntColumn get prepMinutes => integer().nullable()();

  /// 实际烹饪时间，单位为分钟；尚未填写时为空。
  IntColumn get cookMinutes => integer().nullable()();

  /// 面向用户展示的难度名称。
  TextColumn get difficulty => text().withDefault(const Constant('简单'))();

  /// 菜谱的视觉风格标识；默认继承用户的全局选择。
  TextColumn get presentationStyle =>
      text().withDefault(const Constant('inheritDefault'))();

  /// 固定到本菜谱的模板标识。
  TextColumn get templateId =>
      text().withDefault(const Constant('builtin.journal.basic'))();

  /// 固定到本菜谱的模板版本。
  IntColumn get templateVersion => integer().withDefault(const Constant(1))();

  /// 用户是否已收藏该菜谱。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// 最近一次完成烹饪的时间；从未做过时为空。
  DateTimeColumn get lastCookedAt => dateTime().nullable()();

  /// 已完成烹饪的累计次数。
  IntColumn get cookCount => integer().withDefault(const Constant(0))();

  /// 菜谱生命周期状态的稳定字符串值。
  TextColumn get status => text().withDefault(const Constant('ready'))();

  /// 默认封面使用的 ARGB 颜色整数。
  IntColumn get coverColor => integer()();

  /// 菜谱首次创建时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 菜谱内容或状态最近更新时间，用于默认排序。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 食材分组（如“主料”“调料”），通过 [position] 保存用户定义的展示顺序。
class IngredientGroups extends Table {
  /// 食材分组主键。
  TextColumn get id => text()();

  /// 所属菜谱 ID；删除菜谱时级联删除分组。
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// 分组名称，例如“主料”或“调料”。
  TextColumn get name => text()();

  /// 分组在菜谱中的零基排序位置。
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 单条食材同时保留原始用量文本和可选数值。
///
/// `amountText` 用于忠实展示“少许”等自然语言；`amountValue + unit` 为未来份量换算预留。
class Ingredients extends Table {
  /// 食材记录主键。
  TextColumn get id => text()();

  /// 所属菜谱 ID；删除菜谱时级联删除食材。
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// 可选的食材分组 ID。
  TextColumn get groupId => text().nullable().references(
    IngredientGroups,
    #id,
    // 删除分组不等于删除食材，失去分组的食材仍保留在菜谱中。
    onDelete: KeyAction.setNull,
  )();

  /// 食材名称。
  TextColumn get name => text()();

  /// 面向用户展示的完整用量文本。
  TextColumn get amountText => text().withDefault(const Constant('适量'))();

  /// 可参与份量换算的数值；无法量化时为空。
  RealColumn get amountValue => real().nullable()();

  /// 结构化计量单位；未解析出单位时为空。
  TextColumn get unit => text().nullable()();

  /// 使用前的处理方式；未填写时为空。
  TextColumn get preparation => text().nullable()();

  /// 是否属于可以省略的食材。
  BoolColumn get isOptional => boolean().withDefault(const Constant(false))();

  /// 食材在菜谱中的零基排序位置。
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 步骤单独建表，便于按顺序读取，并为逐步烹饪的时长、火候信息留出结构化字段。
class RecipeSteps extends Table {
  /// 步骤记录主键。
  TextColumn get id => text()();

  /// 所属菜谱 ID；删除菜谱时级联删除步骤。
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// 步骤在菜谱中的零基执行顺序。
  IntColumn get position => integer()();

  /// 可选的步骤小标题。
  TextColumn get title => text().nullable()();

  /// 用户实际阅读和执行的操作说明。
  TextColumn get instruction => text()();

  /// 预计执行分钟数；未设置计时时为空。
  IntColumn get durationMinutes => integer().nullable()();

  /// 火力描述；不适用时为空。
  TextColumn get heatLevel => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 标签使用关联表表达“一道菜多个标签”，组合唯一键防止同一道菜重复添加同一标签。
class RecipeTags extends Table {
  /// 关联记录的自增主键。
  IntColumn get id => integer().autoIncrement()();

  /// 所属菜谱 ID；删除菜谱时级联删除标签关联。
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// 标签的显示名称。
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

  /// Drift 查询得到的菜谱主表行。
  final Recipe recipe;

  /// 该菜谱的全部食材分组行。
  final List<IngredientGroup> groups;

  /// 该菜谱的全部食材行。
  final List<Ingredient> ingredients;

  /// 该菜谱的全部步骤行。
  final List<RecipeStep> steps;

  /// 从标签关联行提取出的标签名称。
  final List<String> tags;
}

class RecipeSummaryData {
  const RecipeSummaryData({
    required this.recipe,
    required this.groups,
    required this.ingredients,
  });

  /// Drift 查询得到的菜谱主表行。
  final Recipe recipe;

  /// 生成手账摘要所需的食材分组行。
  final List<IngredientGroup> groups;

  /// 生成手账摘要所需的食材行。
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
      // 种子数据只在首次建库时写入，升级已有数据库不会重复插入示例菜谱。
      await _seedExampleRecipes();
    },
    onUpgrade: (migrator, from, to) async {
      // 迁移按旧版本逐段执行。以后增加 v3 时应继续追加 `if (from < 3)`，
      // 这样从 v1 直接升级到 v3 也会依次补齐所有结构。
      if (from < 2) {
        await migrator.addColumn(recipes, recipes.templateId);
        await migrator.addColumn(recipes, recipes.templateVersion);
      }
    },
    beforeOpen: (details) async {
      // SQLite 每个连接都要显式开启外键检查，否则 cascade/setNull 不会生效。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// 监听符合搜索和快捷筛选条件的菜谱主表。
  ///
  /// Drift 的 `watch()` 会追踪本查询依赖的表，相关写入后自动重新发出结果。
  Stream<List<Recipe>> watchRecipes({
    String query = '',
    String statusFilter = 'all',
  }) {
    final statement = select(recipes);
    final normalized = query.trim();
    if (normalized.isNotEmpty) {
      final pattern = '%$normalized%';
      // EXISTS 只判断是否有匹配子项，不会像 JOIN 一样把同一道菜复制成多行。
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
    // 列表卡片需要主料摘要，所以一次监听主表、食材和分组。
    // leftOuterJoin 保证没有食材的“待完善”菜谱仍会出现在结果中。
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
      // 一对多 JOIN 会为每条食材返回一行。这里按 recipe.id 折叠回“一道菜一个摘要”，
      // 防止列表重复卡片，同时收集该菜的食材和去重后的分组。
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
    // 先确认主记录存在；不存在时直接返回 null，供 Domain/UI 展示“菜谱不存在”。
    final recipe = await (select(
      recipes,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (recipe == null) return null;

    // 详情读取的是多个规范化子表，Data 层把它们组装成一个内部数据快照，
    // 再由 Mapper 转成不含 Drift 类型的领域实体。
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
    // 收藏会影响默认的“最近更新”排序，因此和收藏值一起刷新 updatedAt。
    return (update(recipes)..where((row) => row.id.equals(id))).write(
      RecipesCompanion(
        isFavorite: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _seedExampleRecipes() async {
    final now = DateTime.now();
    // batch 将多条 INSERT 合并执行，适合无条件的首次建库种子数据。
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

  /// 当前正在聚合的菜谱主表行。
  final Recipe recipe;

  /// 以分组 ID 去重收集的食材分组行。
  final Map<String, IngredientGroup> groups = {};

  /// 按 JOIN 查询顺序收集的食材行。
  final List<Ingredient> ingredients = [];
}

LazyDatabase _openConnection() {
  // LazyDatabase 把路径查询和 SQLite 打开放到真正首次访问数据库时；
  // createInBackground 则避免 SQLite I/O 阻塞 Flutter UI isolate。
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'kitchen_notes.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
