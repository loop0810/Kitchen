import '../../collection/entities/kitchen_recipe_domain_recipe_collection_entity.dart';
import '../../recipe/entities/kitchen_recipe_domain_recipe_journal_summary_entity.dart';

/// 一页菜谱集阅读内容及其标题分组。
class RecipeCollectionReaderEntryEntity {
  const RecipeCollectionReaderEntryEntity({
    required this.recipe,
    required this.groupLabel,
  });

  /// 当前阅读页使用的手账摘要。
  final RecipeJournalSummaryEntity recipe;

  /// 标题对应的 `A-Z` 分组；无法归入字母分组时为 `#`。
  final String groupLabel;
}

/// 打开阅读器时固定下来的菜谱集阅读范围。
class RecipeCollectionReaderSnapshotEntity {
  const RecipeCollectionReaderSnapshotEntity({
    required this.collection,
    required this.entries,
  });

  /// 本次翻阅所属的菜谱集。
  final RecipeCollectionEntity collection;

  /// 按阅读顺序排列的有效菜谱；阅读期间不自动插入新成员。
  final List<RecipeCollectionReaderEntryEntity> entries;
}

/// 可替换的菜谱标题阅读顺序策略。
abstract interface class RecipeReadingOrderPolicy {
  /// 比较两个手账摘要的阅读顺序。
  int compare(
    RecipeJournalSummaryEntity left,
    RecipeJournalSummaryEntity right,
  );

  /// 返回标题在阅读器中显示的 `A-Z` 或 `#` 分组。
  String groupLabelFor(String title);
}
