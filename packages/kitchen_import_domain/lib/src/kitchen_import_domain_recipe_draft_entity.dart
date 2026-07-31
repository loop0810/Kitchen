enum DraftFieldOrigin { source, inferred, userEdited, userConfirmed }

class DraftFieldValue<T> {
  const DraftFieldValue({
    required this.value,
    required this.origin,
    this.needsConfirmation = false,
  });

  /// 当前字段值；无法可靠推断时允许为空值或空集合。
  final T value;

  /// 当前值来自原文、规则推断、用户编辑或用户确认。
  final DraftFieldOrigin origin;

  /// 是否需要在保存正式菜谱前提醒用户确认。
  final bool needsConfirmation;
}

class SourceSnapshot {
  const SourceSnapshot({
    required this.originalText,
    this.publicUrl,
    this.sourceTitle,
  });

  /// 用户粘贴或系统分享的原始文字，不会被解析结果覆盖。
  final String originalText;

  /// 从原文识别出的公开 HTTPS 地址；未识别时为空。
  final Uri? publicUrl;

  /// 网页或分享来源标题；未成功提取时为空。
  final String? sourceTitle;
}

class RecipeDraftEntity {
  const RecipeDraftEntity({
    required this.title,
    required this.summary,
    required this.category,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.sourceSnapshot,
    this.schemaVersion = 1,
  });

  /// 版本化草稿结构版本，用于数据库恢复和未来迁移。
  final int schemaVersion;

  /// 菜名及其来源标记。
  final DraftFieldValue<String> title;

  /// 菜谱简介及其来源标记。
  final DraftFieldValue<String> summary;

  /// 唯一主分类及其来源标记。
  final DraftFieldValue<String> category;

  /// 建议份量，单位为人数；无法判断时为空。
  final DraftFieldValue<int?> servings;

  /// 准备时间，单位为分钟；无法判断时为空。
  final DraftFieldValue<int?> prepMinutes;

  /// 烹饪时间，单位为分钟；无法判断时为空。
  final DraftFieldValue<int?> cookMinutes;

  /// 难度文案；无法判断时为空字符串。
  final DraftFieldValue<String> difficulty;

  /// 标签列表，顺序为本地解析器给出的建议顺序。
  final DraftFieldValue<List<String>> tags;

  /// 食材自然语言行，顺序即最终展示顺序。
  final DraftFieldValue<List<String>> ingredients;

  /// 烹饪步骤，顺序即最终执行顺序。
  final DraftFieldValue<List<String>> steps;

  /// 与草稿分开保存的原始来源快照。
  final SourceSnapshot sourceSnapshot;
}
