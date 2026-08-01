import 'package:drift/drift.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:uuid/uuid.dart';

import 'kitchen_recipe_data_app_database.dart';
import 'kitchen_recipe_data_pinyin_recipe_reading_order_policy.dart';
import 'kitchen_recipe_data_recipe_mapper.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(
    this._database, {
    this._readingOrderPolicy = const PinyinRecipeReadingOrderPolicy(),
  });

  final AppDatabase _database;
  final RecipeReadingOrderPolicy _readingOrderPolicy;
  final _uuid = const Uuid();

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    // Repository 负责把领域查询翻译为数据库参数，并把数据库快照映射回领域对象。
    return _database
        .watchRecipeSummaries(
          query: query.text,
          statusFilter: _statusFilterToData(query.statusFilter),
          scope: query.scope.name,
          sortOrder: query.sortOrder.name,
        )
        .map((summaries) {
          final result = summaries.map(RecipeMapper.summaryToDomain).toList();
          if (query.sortOrder == RecipeSortOrder.title) {
            result.sort(_compareRecipeTitles);
          }
          return List.unmodifiable(result);
        });
  }

  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) {
    return _database.setFavorite(recipeId, value: isFavorite);
  }

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async {
    final detail = await _database.getRecipeDetail(recipeId);
    return detail == null ? null : RecipeMapper.detailToDomain(detail);
  }

  @override
  Future<String> createRecipe(CreateRecipeInput input) async {
    final importTaskId = input.importTaskId;
    if (importTaskId != null) {
      final existingId = await _database.recipeIdForImportTask(importTaskId);
      if (existingId != null) return existingId;
    }
    final recipeId = _uuid.v4();
    final now = DateTime.now();
    final incomplete = input.ingredients.isEmpty || input.steps.isEmpty;

    // 菜谱主记录、食材和步骤必须原子写入：任意一条失败时，
    // transaction 会回滚全部更改，数据库不会留下“半份菜谱”。
    await _database.transaction(() async {
      await _database
          .into(_database.recipes)
          .insert(
            RecipesCompanion.insert(
              id: recipeId,
              title: input.title.trim(),
              summary: Value(input.summary.trim()),
              category: Value(input.category),
              servings: Value(input.servings),
              prepMinutes: Value(input.prepMinutes),
              cookMinutes: Value(input.cookMinutes),
              difficulty: Value(
                input.difficulty.trim().isEmpty
                    ? '简单'
                    : input.difficulty.trim(),
              ),
              templateId: Value(input.templateSelection.templateId),
              templateVersion: Value(input.templateSelection.templateVersion),
              status: Value(incomplete ? 'incomplete' : 'ready'),
              coverColor: _coverColorFor(input.title),
              createdAt: now,
              updatedAt: now,
              importTaskId: Value(input.importTaskId),
              sourceOriginalText: Value(input.sourceSnapshot?.originalText),
              sourcePublicUrl: Value(
                input.sourceSnapshot?.publicUrl?.toString(),
              ),
              sourceTitle: Value(input.sourceSnapshot?.sourceTitle),
            ),
          );

      if (input.ingredients.isNotEmpty) {
        for (final (index, line) in input.ingredients.indexed) {
          // 用户输入仍是自然语言行；Domain Service 先拆出名称和显示用量，
          // Data 层只负责把解析结果持久化。
          final parsed = const IngredientLineParserService()(line);
          await _database
              .into(_database.ingredients)
              .insert(
                IngredientsCompanion.insert(
                  id: _uuid.v4(),
                  recipeId: recipeId,
                  name: parsed.name,
                  amountText: Value(parsed.amountText),
                  position: index,
                ),
              );
        }
      }

      for (final (index, instruction) in input.steps.indexed) {
        await _database
            .into(_database.recipeSteps)
            .insert(
              RecipeStepsCompanion.insert(
                id: _uuid.v4(),
                recipeId: recipeId,
                position: index,
                instruction: instruction,
              ),
            );
      }

      for (final tag
          in input.tags
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)) {
        await _database
            .into(_database.recipeTags)
            .insert(
              RecipeTagsCompanion.insert(recipeId: recipeId, tag: tag),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
    return recipeId;
  }

  @override
  Future<void> updateRecipe(UpdateRecipeInput input) async {
    final existing = await _database.getRecipeDetail(input.recipeId);
    if (existing == null) {
      throw StateError('Recipe ${input.recipeId} does not exist.');
    }

    final existingIngredientIds = existing.ingredients
        .map((ingredient) => ingredient.id)
        .toSet();
    final existingStepIds = existing.steps.map((step) => step.id).toSet();
    final suppliedIngredientIds = input.ingredients
        .map((ingredient) => ingredient.id)
        .nonNulls
        .toList(growable: false);
    final suppliedStepIds = input.steps
        .map((step) => step.id)
        .nonNulls
        .toList(growable: false);
    if (suppliedIngredientIds.toSet().length != suppliedIngredientIds.length ||
        suppliedStepIds.toSet().length != suppliedStepIds.length ||
        !existingIngredientIds.containsAll(suppliedIngredientIds) ||
        !existingStepIds.containsAll(suppliedStepIds)) {
      // 稳定 ID 只能引用当前菜谱已有的子项，防止错误输入覆盖其他菜谱的数据。
      throw ArgumentError('Ingredient or step ID does not belong to recipe.');
    }

    final now = DateTime.now();
    final status = input.ingredients.isEmpty || input.steps.isEmpty
        ? 'incomplete'
        : 'ready';

    // 更新主表并同步两个有序子表必须处于同一事务。收藏、烹饪统计、创建时间、
    // 标签以及当前编辑器尚未覆盖的主表字段都不会被这次写入改动。
    await _database.transaction(() async {
      await (_database.update(
        _database.recipes,
      )..where((row) => row.id.equals(input.recipeId))).write(
        RecipesCompanion(
          title: Value(input.title.trim()),
          summary: Value(input.summary.trim()),
          category: Value(input.category.trim()),
          templateId: Value(input.templateSelection.templateId),
          templateVersion: Value(input.templateSelection.templateVersion),
          status: Value(status),
          updatedAt: Value(now),
        ),
      );

      final keptIngredientIds = suppliedIngredientIds.toSet();
      await (_database.delete(_database.ingredients)..where(
            (row) =>
                row.recipeId.equals(input.recipeId) &
                (keptIngredientIds.isEmpty
                    ? const Constant(true)
                    : row.id.isNotIn(keptIngredientIds)),
          ))
          .go();
      for (final (position, ingredient) in input.ingredients.indexed) {
        await _database
            .into(_database.ingredients)
            .insertOnConflictUpdate(
              IngredientsCompanion.insert(
                id: ingredient.id ?? _uuid.v4(),
                recipeId: input.recipeId,
                name: ingredient.name.trim(),
                amountText: Value(ingredient.amountText.trim()),
                amountValue: Value(ingredient.amountValue),
                unit: Value(ingredient.unit),
                preparation: Value(ingredient.preparation),
                isOptional: Value(ingredient.isOptional),
                position: position,
              ),
            );
      }

      final keptStepIds = suppliedStepIds.toSet();
      await (_database.delete(_database.recipeSteps)..where(
            (row) =>
                row.recipeId.equals(input.recipeId) &
                (keptStepIds.isEmpty
                    ? const Constant(true)
                    : row.id.isNotIn(keptStepIds)),
          ))
          .go();
      for (final (position, step) in input.steps.indexed) {
        await _database
            .into(_database.recipeSteps)
            .insertOnConflictUpdate(
              RecipeStepsCompanion.insert(
                id: step.id ?? _uuid.v4(),
                recipeId: input.recipeId,
                position: position,
                title: Value(step.title),
                instruction: step.instruction.trim(),
                durationMinutes: Value(step.durationMinutes),
                heatLevel: Value(step.heatLevel),
              ),
            );
      }
    });
  }

  String _statusFilterToData(RecipeStatusFilter filter) {
    return switch (filter) {
      RecipeStatusFilter.all => 'all',
      RecipeStatusFilter.favorite => 'favorite',
      RecipeStatusFilter.cooked => 'cooked',
      RecipeStatusFilter.incomplete => 'incomplete',
    };
  }

  int _coverColorFor(String title) {
    const colors = [0xFFF4B9A8, 0xFFF1CA7B, 0xFFAFC5A7, 0xFFB9CBE0, 0xFFE4B8C5];
    // 用标题散列选择初始颜色，无需维护随机状态；选中结果会随菜谱一起持久化。
    return colors[title.hashCode.abs() % colors.length];
  }

  int _compareRecipeTitles(
    RecipeJournalSummaryEntity left,
    RecipeJournalSummaryEntity right,
  ) => _readingOrderPolicy.compare(left, right);
}
