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

  /// 历史烹饪时间列；仅为旧版 SQLite 兼容保留，新代码不读写。
  DateTimeColumn get lastCookedAt => dateTime().nullable()();

  /// 历史烹饪次数列；仅为旧版 SQLite 兼容保留，新代码不读写。
  IntColumn get cookCount => integer().withDefault(const Constant(0))();

  /// 菜谱生命周期状态的稳定字符串值。
  TextColumn get status => text().withDefault(const Constant('ready'))();

  /// 移入回收站的时间；未删除菜谱为空。
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// 删除前生命周期状态；恢复完成后清空。
  TextColumn get statusBeforeDeletion => text().nullable()();

  /// 默认封面使用的 ARGB 颜色整数。
  IntColumn get coverColor => integer()();

  /// 菜谱首次创建时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 菜谱内容或状态最近更新时间，用于默认排序。
  DateTimeColumn get updatedAt => dateTime()();

  /// 生成本菜谱的导入任务 ID；手动创建时为空，非空值全库唯一。
  TextColumn get importTaskId => text().nullable().unique()();

  /// 导入时保存的原始来源文字；手动创建或没有来源时为空。
  TextColumn get sourceOriginalText => text().nullable()();

  /// 导入来源的公开 HTTPS 地址；没有链接时为空。
  TextColumn get sourcePublicUrl => text().nullable()();

  /// 导入来源标题；未提取成功时为空。
  TextColumn get sourceTitle => text().nullable()();

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

/// 用户维护的菜谱集；名称允许重复，列表按创建时间稳定展示。
class RecipeCollections extends Table {
  /// 菜谱集主键。
  TextColumn get id => text()();

  /// 去除首尾空格的名称，最长 40 字。
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// 菜谱集在列表中的零基展示位置。
  ///
  /// v6 起仅为兼容旧数据库保留，不再参与产品排序。
  IntColumn get position => integer()();

  /// 受控封面目录中的相对 JPEG 路径；未设置自定义封面时为空。
  TextColumn get coverPath => text().nullable()();

  /// 菜谱集首次创建时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 名称、成员或展示位置最近变更时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 菜谱与菜谱集的多对多关系。
class RecipeCollectionMembers extends Table {
  /// 所属菜谱集 ID；删除集合时只级联删除关系。
  TextColumn get collectionId =>
      text().references(RecipeCollections, #id, onDelete: KeyAction.cascade)();

  /// 成员菜谱 ID；永久删除菜谱时级联删除关系。
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// 加入集合的时间，用于集合详情默认排序。
  DateTimeColumn get addedAt => dateTime()();

  /// 成员在集合中的零基位置；软删除菜谱时保留。
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, recipeId};
}

/// 菜谱库单例设置，避免 Feature 直接接触本地数据库。
class RecipeLibrarySettings extends Table {
  /// 固定为 1 的单例主键。
  IntColumn get id => integer()();

  /// 上次选择的菜谱库排序稳定字符串值。
  TextColumn get sortOrder =>
      text().withDefault(const Constant('recentlyUpdated'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 当前账号的个性化食谱配置缓存。
///
/// UI 只监听本表，不直接读取远端响应；同步成功或本地编辑都通过 Repository
/// 原子更新同一行，从而让所有 Feature 看到一致快照。
class PersonalRecipeConfigCache extends Table {
  /// 配置所属命名空间，如 `device:anonymous` 或 `account:<userId>`。
  TextColumn get namespace => text()();

  /// 按用户顺序保存的分类 JSON 数组。
  TextColumn get categoriesJson => text()();

  /// 按用户顺序保存的标签 JSON 数组。
  TextColumn get tagsJson => text()();

  /// 按用户顺序保存的难度 JSON 数组，首项为默认难度。
  TextColumn get difficultiesJson => text()();

  /// 服务端配置修订号；尚未成功同步时为空。
  TextColumn get serverRevision => text().nullable()();

  /// 是否存在尚未上传成功的本地修改。
  BoolColumn get syncPending => boolean().withDefault(const Constant(false))();

  /// 最近一次成功同步时间；从未同步时为空。
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// 缓存最近更新时间，用于诊断和备份合并。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {namespace};
}

class RecipeDetailData {
  const RecipeDetailData({
    required this.recipe,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });

  /// Drift 查询得到的菜谱主表行。
  final Recipe recipe;

  /// 该菜谱的全部食材行。
  final List<Ingredient> ingredients;

  /// 该菜谱的全部步骤行。
  final List<RecipeStep> steps;

  /// 从标签关联行提取出的标签名称。
  final List<String> tags;
}

class RecipeSummaryData {
  const RecipeSummaryData({required this.recipe, required this.ingredients});

  /// Drift 查询得到的菜谱主表行。
  final Recipe recipe;

  /// 生成手账摘要所需的食材行。
  final List<Ingredient> ingredients;
}

class RecipeCollectionSummaryData {
  const RecipeCollectionSummaryData({
    required this.collection,
    required this.memberCount,
  });

  /// 菜谱集主表行。
  final RecipeCollection collection;

  /// 未删除成员数量。
  final int memberCount;
}

class RecipeCollectionMemberData {
  const RecipeCollectionMemberData({
    required this.recipe,
    required this.addedAt,
    required this.position,
  });

  /// 成员菜谱摘要。
  final RecipeSummaryData recipe;

  /// 菜谱加入集合的时间。
  final DateTime addedAt;

  /// 成员在集合内的稳定位置。
  final int position;
}

class RecipeCollectionDetailData {
  const RecipeCollectionDetailData({
    required this.summary,
    required this.members,
  });

  /// 集合自身及封面摘要。
  final RecipeCollectionSummaryData summary;

  /// 未删除成员，按位置升序。
  final List<RecipeCollectionMemberData> members;
}

@DriftDatabase(
  tables: [
    Recipes,
    Ingredients,
    RecipeSteps,
    RecipeTags,
    RecipeCollections,
    RecipeCollectionMembers,
    RecipeLibrarySettings,
    PersonalRecipeConfigCache,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

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
      if (from < 3) {
        // v3 取消食材分组。先移除食材表外键列，再删除分组表；迁移只删除
        // 已废弃的结构，食材本身及其全局 position 顺序保持不变。
        await migrator.dropColumn(ingredients, 'group_id');
        await migrator.deleteTable('ingredient_groups');
      }
      if (from < 4) {
        // v4 为导入确认增加来源快照和幂等键。导入任务 ID 的唯一索引由
        // Drift 随列约束创建，防止崩溃恢复后重复生成正式菜谱。
        // SQLite 不允许通过 ALTER TABLE 直接新增 UNIQUE 列，因此先新增普通
        // nullable 列，再单独建立唯一索引；新建数据库仍由表声明生成同等约束。
        await customStatement(
          'ALTER TABLE recipes ADD COLUMN import_task_id TEXT NULL',
        );
        await customStatement(
          'CREATE UNIQUE INDEX recipes_import_task_id_unique '
          'ON recipes (import_task_id)',
        );
        await migrator.addColumn(recipes, recipes.sourceOriginalText);
        await migrator.addColumn(recipes, recipes.sourcePublicUrl);
        await migrator.addColumn(recipes, recipes.sourceTitle);
      }
      if (from < 5) {
        await migrator.addColumn(recipes, recipes.deletedAt);
        await migrator.addColumn(recipes, recipes.statusBeforeDeletion);
        await migrator.createTable(recipeCollections);
        await migrator.createTable(recipeCollectionMembers);
        await migrator.createTable(recipeLibrarySettings);
        // 旧版已经标记 deleted 的记录没有精确删除时间，使用最近更新时间作为
        // 可解释的迁移基线；恢复时会根据详情完整度推断缺失的删除前状态。
        await customStatement(
          "UPDATE recipes SET deleted_at = updated_at WHERE status = 'deleted'",
        );
      }
      if (from == 5) {
        await migrator.addColumn(
          recipeCollections,
          recipeCollections.coverPath,
        );
        await migrator.addColumn(
          recipeCollectionMembers,
          recipeCollectionMembers.position,
        );
        // 升级前成员按 addedAt 倒序、recipeId 升序展示。相关子查询把同一集合
        // 中排在当前成员之前的行数写为 position，从而保持升级前视觉顺序。
        await customStatement('''
UPDATE recipe_collection_members AS current
SET position = (
  SELECT COUNT(*)
  FROM recipe_collection_members AS preceding
  WHERE preceding.collection_id = current.collection_id
    AND (
      preceding.added_at > current.added_at
      OR (
        preceding.added_at = current.added_at
        AND preceding.recipe_id < current.recipe_id
      )
    )
)
''');
      }
      if (from < 7) {
        // v7 的旧表使用整数单例主键。先按旧结构创建，下一段再统一迁移到
        // 命名空间主键，确保从 v1～v6 升级时也能走同一条安全路径。
        await customStatement('''
CREATE TABLE personal_recipe_config_cache (
  id INTEGER NOT NULL PRIMARY KEY,
  categories_json TEXT NOT NULL,
  tags_json TEXT NOT NULL,
  difficulties_json TEXT NOT NULL,
  server_revision TEXT,
  sync_pending INTEGER NOT NULL DEFAULT 0,
  last_synced_at INTEGER,
  updated_at INTEGER NOT NULL
)
''');
      }
      if (from < 8) {
        // v7 的单例配置无法判断历史账号归属，安全迁移到匿名本机命名空间。
        // 旧 pending 也只能保留在本机，不能在首次登录时自动上传。
        await customStatement(
          'ALTER TABLE personal_recipe_config_cache '
          'RENAME TO personal_recipe_config_cache_legacy',
        );
        await migrator.createTable(personalRecipeConfigCache);
        await customStatement('''
INSERT INTO personal_recipe_config_cache
  (namespace, categories_json, tags_json, difficulties_json,
   server_revision, sync_pending, last_synced_at, updated_at)
SELECT 'device:anonymous', categories_json, tags_json, difficulties_json,
       NULL, 0, NULL, updated_at
FROM personal_recipe_config_cache_legacy
WHERE id = 1
''');
        await migrator.deleteTable('personal_recipe_config_cache_legacy');
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
    String scope = 'library',
    String sortOrder = 'recentlyUpdated',
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
    } else if (statusFilter == 'incomplete') {
      statement.where((recipe) => recipe.status.equals('incomplete'));
    }
    _applyRecipeScope(statement, scope);
    _applyRecipeOrdering(statement, sortOrder);
    return statement.watch();
  }

  Stream<List<RecipeSummaryData>> watchRecipeSummaries({
    String query = '',
    String statusFilter = 'all',
    String scope = 'library',
    String sortOrder = 'recentlyUpdated',
  }) {
    // 列表卡片需要食材摘要，所以一次监听主表和食材。
    // leftOuterJoin 保证没有食材的“待完善”菜谱仍会出现在结果中。
    final statement = select(recipes).join([
      leftOuterJoin(ingredients, ingredients.recipeId.equalsExp(recipes.id)),
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
    } else if (statusFilter == 'incomplete') {
      statement.where(recipes.status.equals('incomplete'));
    }
    if (scope == 'trash') {
      statement.where(recipes.status.equals('deleted'));
    } else {
      statement.where(recipes.status.isIn(['ready', 'incomplete']));
    }
    statement.orderBy([
      ..._recipeOrderingTerms(sortOrder),
      OrderingTerm.asc(ingredients.position),
    ]);

    return statement.watch().map((rows) {
      // 一对多 JOIN 会为每条食材返回一行。这里按 recipe.id 折叠回“一道菜一个摘要”，
      // 防止列表重复卡片，同时按 position 收集该菜的食材。
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
      }
      return summaries.values
          .map(
            (summary) => RecipeSummaryData(
              recipe: summary.recipe,
              ingredients: summary.ingredients,
            ),
          )
          .toList(growable: false);
    });
  }

  void _applyRecipeScope(
    SimpleSelectStatement<Recipes, Recipe> statement,
    String scope,
  ) {
    if (scope == 'trash') {
      statement.where((recipe) => recipe.status.equals('deleted'));
    } else {
      statement.where((recipe) => recipe.status.isIn(['ready', 'incomplete']));
    }
  }

  void _applyRecipeOrdering(
    SimpleSelectStatement<Recipes, Recipe> statement,
    String order,
  ) {
    statement.orderBy([
      (recipe) => switch (order) {
        'recentlySaved' => OrderingTerm.desc(recipe.createdAt),
        'title' => OrderingTerm.asc(recipe.title),
        _ => OrderingTerm.desc(recipe.updatedAt),
      },
      (recipe) => OrderingTerm.asc(recipe.id),
    ]);
  }

  List<OrderingTerm> _recipeOrderingTerms(String order) {
    return switch (order) {
      'recentlySaved' => [
        OrderingTerm.desc(recipes.createdAt),
        OrderingTerm.asc(recipes.id),
      ],
      'title' => [
        OrderingTerm.asc(recipes.title),
        OrderingTerm.asc(recipes.id),
      ],
      _ => [OrderingTerm.desc(recipes.updatedAt), OrderingTerm.asc(recipes.id)],
    };
  }

  Future<RecipeDetailData?> getRecipeDetail(String id) async {
    // 先确认主记录存在；不存在时直接返回 null，供 Domain/UI 展示“菜谱不存在”。
    final recipe = await (select(
      recipes,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (recipe == null) return null;

    // 详情读取的是多个规范化子表，Data 层把它们组装成一个内部数据快照，
    // 再由 Mapper 转成不含 Drift 类型的领域实体。
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
      ingredients: ingredientRows,
      steps: stepRows,
      tags: tagRows.map((row) => row.tag).toList(),
    );
  }

  Stream<List<RecipeCollectionSummaryData>> watchCollectionSummaries() {
    final changes = customSelect(
      'SELECT c.id FROM recipe_collections c '
      'LEFT JOIN recipe_collection_members m ON m.collection_id = c.id '
      'LEFT JOIN recipes r ON r.id = m.recipe_id',
      readsFrom: {recipeCollections, recipeCollectionMembers, recipes},
    ).watch();
    return changes.asyncMap((_) => _loadCollectionSummaries());
  }

  Future<List<RecipeCollectionSummaryData>> _loadCollectionSummaries() async {
    final rows =
        await (select(recipeCollections)..orderBy([
              (row) => OrderingTerm.asc(row.createdAt),
              // 多个集合可能在数据库时间精度内同刻创建；保留的创建位置用于稳定
              // 还原实际追加顺序，不重新开放集合手动排序能力。
              (row) => OrderingTerm.asc(row.position),
              (row) => OrderingTerm.asc(row.id),
            ]))
            .get();
    final results = <RecipeCollectionSummaryData>[];
    for (final collection in rows) {
      final members = await _loadCollectionMembers(collection.id);
      results.add(
        RecipeCollectionSummaryData(
          collection: collection,
          memberCount: members.length,
        ),
      );
    }
    return results;
  }

  Future<RecipeCollectionDetailData?> getCollectionDetail(String id) async {
    final collection = await (select(
      recipeCollections,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (collection == null) return null;
    final members = await _loadCollectionMembers(id);
    return RecipeCollectionDetailData(
      summary: RecipeCollectionSummaryData(
        collection: collection,
        memberCount: members.length,
      ),
      members: members,
    );
  }

  Future<List<RecipeCollectionMemberData>> _loadCollectionMembers(
    String id,
  ) async {
    final joined =
        select(recipeCollectionMembers).join([
            innerJoin(
              recipes,
              recipes.id.equalsExp(recipeCollectionMembers.recipeId),
            ),
            leftOuterJoin(
              ingredients,
              ingredients.recipeId.equalsExp(recipes.id),
            ),
          ])
          ..where(
            recipeCollectionMembers.collectionId.equals(id) &
                recipes.status.isNotValue('deleted'),
          )
          ..orderBy([
            OrderingTerm.asc(recipeCollectionMembers.position),
            OrderingTerm.asc(ingredients.position),
          ]);
    final rows = await joined.get();
    final aggregates = <String, _MutableCollectionMember>{};
    for (final row in rows) {
      final recipe = row.readTable(recipes);
      final relation = row.readTable(recipeCollectionMembers);
      final aggregate = aggregates.putIfAbsent(
        recipe.id,
        () => _MutableCollectionMember(
          recipe,
          relation.addedAt,
          relation.position,
        ),
      );
      final ingredient = row.readTableOrNull(ingredients);
      if (ingredient != null) aggregate.ingredients.add(ingredient);
    }
    return aggregates.values
        .map(
          (value) => RecipeCollectionMemberData(
            recipe: RecipeSummaryData(
              recipe: value.recipe,
              ingredients: value.ingredients,
            ),
            addedAt: value.addedAt,
            position: value.position,
          ),
        )
        .toList(growable: false);
  }

  Future<int> nextCollectionPosition() async {
    final expression = recipeCollections.position.max();
    final row = await (selectOnly(
      recipeCollections,
    )..addColumns([expression])).getSingle();
    return (row.read(expression) ?? -1) + 1;
  }

  Future<Set<String>> collectionIdsForRecipe(String recipeId) async {
    final rows = await (select(
      recipeCollectionMembers,
    )..where((row) => row.recipeId.equals(recipeId))).get();
    return rows.map((row) => row.collectionId).toSet();
  }

  Future<void> replaceCollectionsForRecipe({
    required String recipeId,
    required Set<String> collectionIds,
  }) async {
    await transaction(() async {
      final recipe = await (select(
        recipes,
      )..where((row) => row.id.equals(recipeId))).getSingleOrNull();
      if (recipe == null || recipe.status == 'deleted') {
        throw StateError('Recipe is missing or deleted.');
      }
      final existingCollections = await (select(
        recipeCollections,
      )..where((row) => row.id.isIn(collectionIds))).get();
      if (existingCollections.length != collectionIds.length) {
        throw StateError('One or more collections do not exist.');
      }
      final previousRows = await (select(
        recipeCollectionMembers,
      )..where((row) => row.recipeId.equals(recipeId))).get();
      final previousAddedAt = {
        for (final row in previousRows) row.collectionId: row.addedAt,
      };
      final previous = previousAddedAt.keys.toSet();
      await (delete(
        recipeCollectionMembers,
      )..where((row) => row.recipeId.equals(recipeId))).go();
      final now = DateTime.now();
      for (final id in collectionIds) {
        await into(recipeCollectionMembers).insert(
          RecipeCollectionMembersCompanion.insert(
            collectionId: id,
            recipeId: recipeId,
            addedAt: previousAddedAt[id] ?? now,
            position: Value(
              previousRows
                      .where((row) => row.collectionId == id)
                      .firstOrNull
                      ?.position ??
                  await nextMemberPosition(id),
            ),
          ),
        );
      }
      await (update(recipeCollections)
            ..where((row) => row.id.isIn(previous.union(collectionIds))))
          .write(RecipeCollectionsCompanion(updatedAt: Value(now)));
    });
  }

  Future<int> nextMemberPosition(String collectionId) async {
    final expression = recipeCollectionMembers.position.max();
    final row =
        await (selectOnly(recipeCollectionMembers)
              ..addColumns([expression])
              ..where(
                recipeCollectionMembers.collectionId.equals(collectionId),
              ))
            .getSingle();
    return (row.read(expression) ?? -1) + 1;
  }

  Future<void> appendRecipesToCollection({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) async {
    await transaction(() async {
      final collection = await (select(
        recipeCollections,
      )..where((row) => row.id.equals(collectionId))).getSingleOrNull();
      if (collection == null) throw StateError('Collection does not exist.');
      if (orderedRecipeIds.toSet().length != orderedRecipeIds.length) {
        throw ArgumentError('Recipe append order contains duplicate IDs.');
      }
      final validRecipes =
          await (select(recipes)..where(
                (row) =>
                    row.id.isIn(orderedRecipeIds) &
                    row.status.isNotValue('deleted'),
              ))
              .get();
      if (validRecipes.length != orderedRecipeIds.length) {
        throw StateError('One or more recipes do not exist or are deleted.');
      }
      final oldRows = await (select(
        recipeCollectionMembers,
      )..where((row) => row.collectionId.equals(collectionId))).get();
      final existingIds = oldRows.map((row) => row.recipeId).toSet();
      final now = DateTime.now();
      var position = oldRows.isEmpty
          ? 0
          : oldRows.map((row) => row.position).reduce((a, b) => a > b ? a : b) +
                1;
      for (final recipeId in orderedRecipeIds) {
        if (existingIds.contains(recipeId)) continue;
        await into(recipeCollectionMembers).insert(
          RecipeCollectionMembersCompanion.insert(
            collectionId: collectionId,
            recipeId: recipeId,
            addedAt: now,
            position: Value(position++),
          ),
        );
      }
      await (update(recipeCollections)
            ..where((row) => row.id.equals(collectionId)))
          .write(RecipeCollectionsCompanion(updatedAt: Value(now)));
    });
  }

  Future<int> removeRecipeFromCollection({
    required String collectionId,
    required String recipeId,
  }) async {
    return transaction(() async {
      final member =
          await (select(recipeCollectionMembers)..where(
                (row) =>
                    row.collectionId.equals(collectionId) &
                    row.recipeId.equals(recipeId),
              ))
              .getSingleOrNull();
      if (member == null) throw StateError('Collection member does not exist.');
      await (delete(recipeCollectionMembers)..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.recipeId.equals(recipeId),
          ))
          .go();
      await (update(recipeCollectionMembers)..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.position.isBiggerThanValue(member.position),
          ))
          .write(
            RecipeCollectionMembersCompanion.custom(
              position: recipeCollectionMembers.position - const Constant(1),
            ),
          );
      return member.position;
    });
  }

  Future<void> restoreRecipeToCollection({
    required String collectionId,
    required String recipeId,
    required int position,
  }) async {
    await transaction(() async {
      final count = recipeCollectionMembers.recipeId.count();
      final row =
          await (selectOnly(recipeCollectionMembers)
                ..addColumns([count])
                ..where(
                  recipeCollectionMembers.collectionId.equals(collectionId),
                ))
              .getSingle();
      final boundedPosition = position.clamp(0, row.read(count) ?? 0).toInt();
      await (update(recipeCollectionMembers)..where(
            (member) =>
                member.collectionId.equals(collectionId) &
                member.position.isBiggerOrEqualValue(boundedPosition),
          ))
          .write(
            RecipeCollectionMembersCompanion.custom(
              position: recipeCollectionMembers.position + const Constant(1),
            ),
          );
      await into(recipeCollectionMembers).insert(
        RecipeCollectionMembersCompanion.insert(
          collectionId: collectionId,
          recipeId: recipeId,
          addedAt: DateTime.now(),
          position: Value(boundedPosition),
        ),
      );
    });
  }

  Future<void> reorderCollectionMembers({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) async {
    if (orderedRecipeIds.toSet().length != orderedRecipeIds.length) {
      throw ArgumentError('Member order contains duplicate IDs.');
    }
    await transaction(() async {
      final query =
          select(recipeCollectionMembers).join([
              innerJoin(
                recipes,
                recipes.id.equalsExp(recipeCollectionMembers.recipeId),
              ),
            ])
            ..where(
              recipeCollectionMembers.collectionId.equals(collectionId) &
                  recipes.status.isNotValue('deleted'),
            )
            ..orderBy([OrderingTerm.asc(recipeCollectionMembers.position)]);
      final rows = (await query.get())
          .map((row) => row.readTable(recipeCollectionMembers))
          .toList(growable: false);
      if (rows
              .map((row) => row.recipeId)
              .toSet()
              .difference(orderedRecipeIds.toSet())
              .isNotEmpty ||
          rows.length != orderedRecipeIds.length) {
        throw StateError(
          'Member order must contain every visible member once.',
        );
      }
      final visiblePositions = rows.map((row) => row.position).toList()..sort();
      // 先写负数临时位置，避免未来增加唯一位置约束后交换顺序产生冲突。
      for (final (index, recipeId) in orderedRecipeIds.indexed) {
        await (update(recipeCollectionMembers)..where(
              (row) =>
                  row.collectionId.equals(collectionId) &
                  row.recipeId.equals(recipeId),
            ))
            .write(
              RecipeCollectionMembersCompanion(position: Value(-index - 1)),
            );
      }
      for (final (index, recipeId) in orderedRecipeIds.indexed) {
        await (update(recipeCollectionMembers)..where(
              (row) =>
                  row.collectionId.equals(collectionId) &
                  row.recipeId.equals(recipeId),
            ))
            .write(
              RecipeCollectionMembersCompanion(
                position: Value(visiblePositions[index]),
              ),
            );
      }
    });
  }

  Future<void> moveRecipeToTrash(String id) async {
    await transaction(() async {
      final recipe = await (select(
        recipes,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (recipe == null) throw StateError('Recipe does not exist.');
      if (recipe.status == 'deleted') return;
      await (update(recipes)..where((row) => row.id.equals(id))).write(
        RecipesCompanion(
          status: const Value('deleted'),
          deletedAt: Value(DateTime.now()),
          statusBeforeDeletion: Value(recipe.status),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> restoreRecipeFromTrash(String id) async {
    await transaction(() async {
      final recipe = await (select(
        recipes,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (recipe == null || recipe.status != 'deleted') {
        throw StateError('Deleted recipe does not exist.');
      }
      var restoredStatus = recipe.statusBeforeDeletion;
      if (restoredStatus == null || restoredStatus == 'deleted') {
        final ingredientCount = ingredients.id.count();
        final stepCount = recipeSteps.id.count();
        final ingredientRow =
            await (selectOnly(ingredients)
                  ..addColumns([ingredientCount])
                  ..where(ingredients.recipeId.equals(id)))
                .getSingle();
        final stepRow =
            await (selectOnly(recipeSteps)
                  ..addColumns([stepCount])
                  ..where(recipeSteps.recipeId.equals(id)))
                .getSingle();
        restoredStatus =
            (ingredientRow.read(ingredientCount) ?? 0) > 0 &&
                (stepRow.read(stepCount) ?? 0) > 0
            ? 'ready'
            : 'incomplete';
      }
      await (update(recipes)..where((row) => row.id.equals(id))).write(
        RecipesCompanion(
          status: Value(restoredStatus),
          deletedAt: const Value(null),
          statusBeforeDeletion: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<int> permanentlyDeleteRecipe(String id) {
    return (delete(
      recipes,
    )..where((row) => row.id.equals(id) & row.status.equals('deleted'))).go();
  }

  Future<int> purgeDeletedBefore(DateTime cutoff) {
    return (delete(recipes)..where(
          (row) =>
              row.status.equals('deleted') &
              row.deletedAt.isSmallerOrEqualValue(cutoff),
        ))
        .go();
  }

  Future<String> getSavedSortOrder() async {
    final row = await (select(
      recipeLibrarySettings,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    return row?.sortOrder ?? 'recentlyUpdated';
  }

  Future<void> saveSortOrder(String value) =>
      into(recipeLibrarySettings).insertOnConflictUpdate(
        RecipeLibrarySettingsCompanion.insert(
          id: const Value(1),
          sortOrder: Value(value),
        ),
      );

  /// 清除设备资料库；调用方负责在账号删除流程中再次确认后调用。
  ///
  /// 菜谱及其子表、集合、配置缓存全部在一个事务中删除，避免留下半份本地资料。
  Future<void> clearLocalData() async {
    await transaction(() async {
      await delete(recipeTags).go();
      await delete(recipeSteps).go();
      await delete(ingredients).go();
      await delete(recipeCollectionMembers).go();
      await delete(recipeCollections).go();
      await delete(recipes).go();
      await delete(recipeLibrarySettings).go();
      await delete(personalRecipeConfigCache).go();
    });
  }

  /// 导出不含设备绝对路径的逻辑快照；封面文件由组合根单独收集。
  Future<Map<String, dynamic>> exportLogicalData() async {
    return transaction(() async {
      final recipeRows = await select(recipes).get();
      final ingredientRows = await select(ingredients).get();
      final stepRows = await select(recipeSteps).get();
      final tagRows = await select(recipeTags).get();
      final collectionRows = await select(recipeCollections).get();
      final memberRows = await select(recipeCollectionMembers).get();
      final sortRow = await select(recipeLibrarySettings).getSingleOrNull();
      final configRows = await select(personalRecipeConfigCache).get();
      return {
        'schemaVersion': schemaVersion,
        'recipes': recipeRows.map(_recipeToBackup).toList(growable: false),
        'ingredients': ingredientRows
            .map(_ingredientToBackup)
            .toList(growable: false),
        'steps': stepRows.map(_stepToBackup).toList(growable: false),
        'tags': tagRows.map(_tagToBackup).toList(growable: false),
        'collections': collectionRows
            .map(_collectionToBackup)
            .toList(growable: false),
        'collectionMembers': memberRows
            .map(_memberToBackup)
            .toList(growable: false),
        'sortOrder': sortRow?.sortOrder,
        // 只导出显示配置，不导出 serverRevision、pending 等同步元数据。
        'personalRecipeConfigs': configRows
            .map(
              (row) => {
                'namespace': row.namespace,
                'categoriesJson': row.categoriesJson,
                'tagsJson': row.tagsJson,
                'difficultiesJson': row.difficultiesJson,
              },
            )
            .toList(growable: false),
      };
    });
  }

  /// 将已验证的逻辑快照原子写入当前数据库。
  Future<void> restoreLogicalData(Map<String, dynamic> data) async {
    await transaction(() async {
      await clearLocalData();
      for (final value in (data['recipes'] as List<dynamic>)) {
        final row = value as Map<String, dynamic>;
        await into(recipes).insert(_recipeFromBackup(row));
      }
      for (final value in (data['ingredients'] as List<dynamic>)) {
        await into(
          ingredients,
        ).insert(_ingredientFromBackup(value as Map<String, dynamic>));
      }
      for (final value in (data['steps'] as List<dynamic>)) {
        await into(
          recipeSteps,
        ).insert(_stepFromBackup(value as Map<String, dynamic>));
      }
      for (final value in (data['tags'] as List<dynamic>)) {
        await into(
          recipeTags,
        ).insert(_tagFromBackup(value as Map<String, dynamic>));
      }
      for (final value in (data['collections'] as List<dynamic>)) {
        await into(
          recipeCollections,
        ).insert(_collectionFromBackup(value as Map<String, dynamic>));
      }
      for (final value in (data['collectionMembers'] as List<dynamic>)) {
        await into(
          recipeCollectionMembers,
        ).insert(_memberFromBackup(value as Map<String, dynamic>));
      }
      final sortOrder = data['sortOrder'] as String?;
      if (sortOrder != null) await saveSortOrder(sortOrder);
      for (final value in (data['personalRecipeConfigs'] as List<dynamic>)) {
        final row = value as Map<String, dynamic>;
        await into(personalRecipeConfigCache).insert(
          PersonalRecipeConfigCacheCompanion.insert(
            namespace: row['namespace'] as String,
            categoriesJson: row['categoriesJson'] as String,
            tagsJson: row['tagsJson'] as String,
            difficultiesJson: row['difficultiesJson'] as String,
            syncPending: const Value(false),
            serverRevision: const Value(null),
            lastSyncedAt: const Value(null),
            updatedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  static String _date(DateTime value) => value.toIso8601String();
  static DateTime _parseDate(Object? value) => DateTime.parse(value! as String);

  static Map<String, dynamic> _recipeToBackup(Recipe row) => {
    'id': row.id,
    'title': row.title,
    'summary': row.summary,
    'category': row.category,
    'servings': row.servings,
    'prepMinutes': row.prepMinutes,
    'cookMinutes': row.cookMinutes,
    'difficulty': row.difficulty,
    'presentationStyle': row.presentationStyle,
    'templateId': row.templateId,
    'templateVersion': row.templateVersion,
    'isFavorite': row.isFavorite,
    'status': row.status,
    'deletedAt': row.deletedAt == null ? null : _date(row.deletedAt!),
    'statusBeforeDeletion': row.statusBeforeDeletion,
    'coverColor': row.coverColor,
    'createdAt': _date(row.createdAt),
    'updatedAt': _date(row.updatedAt),
    'importTaskId': row.importTaskId,
    'sourceOriginalText': row.sourceOriginalText,
    'sourcePublicUrl': row.sourcePublicUrl,
    'sourceTitle': row.sourceTitle,
  };

  static RecipesCompanion _recipeFromBackup(Map<String, dynamic> row) =>
      RecipesCompanion.insert(
        id: row['id'] as String,
        title: row['title'] as String,
        summary: Value(row['summary'] as String),
        category: Value(row['category'] as String),
        servings: Value(row['servings'] as int?),
        prepMinutes: Value(row['prepMinutes'] as int?),
        cookMinutes: Value(row['cookMinutes'] as int?),
        difficulty: Value(row['difficulty'] as String),
        presentationStyle: Value(row['presentationStyle'] as String),
        templateId: Value(row['templateId'] as String),
        templateVersion: Value(row['templateVersion'] as int),
        isFavorite: Value(row['isFavorite'] as bool),
        status: Value(row['status'] as String),
        deletedAt: Value(
          row['deletedAt'] == null ? null : _parseDate(row['deletedAt']),
        ),
        statusBeforeDeletion: Value(row['statusBeforeDeletion'] as String?),
        coverColor: row['coverColor'] as int,
        createdAt: _parseDate(row['createdAt']),
        updatedAt: _parseDate(row['updatedAt']),
        importTaskId: Value(row['importTaskId'] as String?),
        sourceOriginalText: Value(row['sourceOriginalText'] as String?),
        sourcePublicUrl: Value(row['sourcePublicUrl'] as String?),
        sourceTitle: Value(row['sourceTitle'] as String?),
      );

  static Map<String, dynamic> _ingredientToBackup(Ingredient row) => {
    'id': row.id,
    'recipeId': row.recipeId,
    'name': row.name,
    'amountText': row.amountText,
    'amountValue': row.amountValue,
    'unit': row.unit,
    'preparation': row.preparation,
    'isOptional': row.isOptional,
    'position': row.position,
  };

  static IngredientsCompanion _ingredientFromBackup(Map<String, dynamic> row) =>
      IngredientsCompanion(
        id: Value(row['id'] as String),
        recipeId: Value(row['recipeId'] as String),
        name: Value(row['name'] as String),
        amountText: Value(row['amountText'] as String),
        amountValue: Value((row['amountValue'] as num?)?.toDouble()),
        unit: Value(row['unit'] as String?),
        preparation: Value(row['preparation'] as String?),
        isOptional: Value(row['isOptional'] as bool),
        position: Value(row['position'] as int),
      );

  static Map<String, dynamic> _stepToBackup(RecipeStep row) => {
    'id': row.id,
    'recipeId': row.recipeId,
    'position': row.position,
    'title': row.title,
    'instruction': row.instruction,
    'durationMinutes': row.durationMinutes,
    'heatLevel': row.heatLevel,
  };

  static RecipeStepsCompanion _stepFromBackup(Map<String, dynamic> row) =>
      RecipeStepsCompanion(
        id: Value(row['id'] as String),
        recipeId: Value(row['recipeId'] as String),
        position: Value(row['position'] as int),
        title: Value(row['title'] as String?),
        instruction: Value(row['instruction'] as String),
        durationMinutes: Value(row['durationMinutes'] as int?),
        heatLevel: Value(row['heatLevel'] as String?),
      );

  static Map<String, dynamic> _tagToBackup(RecipeTag row) => {
    'recipeId': row.recipeId,
    'tag': row.tag,
  };

  static RecipeTagsCompanion _tagFromBackup(Map<String, dynamic> row) =>
      RecipeTagsCompanion(
        recipeId: Value(row['recipeId'] as String),
        tag: Value(row['tag'] as String),
      );

  static Map<String, dynamic> _collectionToBackup(RecipeCollection row) => {
    'id': row.id,
    'name': row.name,
    'position': row.position,
    'coverPath': row.coverPath,
    'createdAt': _date(row.createdAt),
    'updatedAt': _date(row.updatedAt),
  };

  static RecipeCollectionsCompanion _collectionFromBackup(
    Map<String, dynamic> row,
  ) => RecipeCollectionsCompanion(
    id: Value(row['id'] as String),
    name: Value(row['name'] as String),
    position: Value(row['position'] as int),
    coverPath: Value(row['coverPath'] as String?),
    createdAt: Value(_parseDate(row['createdAt'])),
    updatedAt: Value(_parseDate(row['updatedAt'])),
  );

  static Map<String, dynamic> _memberToBackup(RecipeCollectionMember row) => {
    'collectionId': row.collectionId,
    'recipeId': row.recipeId,
    'addedAt': _date(row.addedAt),
    'position': row.position,
  };

  static RecipeCollectionMembersCompanion _memberFromBackup(
    Map<String, dynamic> row,
  ) => RecipeCollectionMembersCompanion(
    collectionId: Value(row['collectionId'] as String),
    recipeId: Value(row['recipeId'] as String),
    addedAt: Value(_parseDate(row['addedAt'])),
    position: Value(row['position'] as int),
  );

  Future<String?> recipeIdForImportTask(String importTaskId) async {
    final row =
        await (selectOnly(recipes)
              ..addColumns([recipes.id])
              ..where(recipes.importTaskId.equals(importTaskId)))
            .getSingleOrNull();
    return row?.read(recipes.id);
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

      batch.insertAll(ingredients, const [
        IngredientsCompanion(
          id: Value('i-tomato'),
          recipeId: Value('sample-tomato-eggs'),
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
          name: Value('盐'),
          amountText: Value('适量'),
          position: Value(2),
        ),
        IngredientsCompanion(
          id: Value('i-oil'),
          recipeId: Value('sample-tomato-eggs'),
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

  /// 按 JOIN 查询顺序收集的食材行。
  final List<Ingredient> ingredients = [];
}

class _MutableCollectionMember {
  _MutableCollectionMember(this.recipe, this.addedAt, this.position);

  /// 当前成员菜谱主表行。
  final Recipe recipe;

  /// 当前关系的加入时间。
  final DateTime addedAt;

  /// 当前成员在集合中的稳定位置。
  final int position;

  /// 当前成员用于手账摘要的食材。
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
