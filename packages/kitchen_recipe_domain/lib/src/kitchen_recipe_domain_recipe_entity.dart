import 'kitchen_recipe_domain_recipe_template_selection_value_object.dart';

enum RecipeStatus { incomplete, ready, archived, deleted }

class RecipeEntity {
  const RecipeEntity({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    required this.presentationStyle,
    required this.templateSelection,
    required this.isFavorite,
    required this.lastCookedAt,
    required this.cookCount,
    required this.status,
    required this.coverColor,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.statusBeforeDeletion,
  });

  /// 菜谱的唯一标识。
  final String id;

  /// 菜谱名称。
  final String title;

  /// 菜谱的简短介绍；没有简介时为空字符串。
  final String summary;

  /// 菜谱所属的唯一主分类。
  final String category;

  /// 适用人数；尚未填写时为空。
  final int? servings;

  /// 准备食材所需分钟数；尚未填写时为空。
  final int? prepMinutes;

  /// 实际烹饪所需分钟数；尚未填写时为空。
  final int? cookMinutes;

  /// 面向用户展示的难度名称。
  final String difficulty;

  /// 菜谱采用的视觉风格标识，例如继承全局默认风格。
  final String presentationStyle;

  /// 当前选用的手账模板及其固定版本。
  final RecipeTemplateSelectionValueObject templateSelection;

  /// 用户是否已收藏这道菜谱。
  final bool isFavorite;

  /// 最近一次完成烹饪的时间；从未做过时为空。
  final DateTime? lastCookedAt;

  /// 已完成烹饪的累计次数。
  final int cookCount;

  /// 菜谱当前所处的生命周期状态。
  final RecipeStatus status;

  /// 用于默认封面背景的 ARGB 颜色整数。
  final int coverColor;

  /// 菜谱首次创建时间。
  final DateTime createdAt;

  /// 菜谱内容或状态最近更新时间。
  final DateTime updatedAt;

  /// 移入回收站的时间；非删除状态时为空。
  final DateTime? deletedAt;

  /// 删除前的生命周期状态；用于恢复，非删除状态时为空。
  final RecipeStatus? statusBeforeDeletion;
}
