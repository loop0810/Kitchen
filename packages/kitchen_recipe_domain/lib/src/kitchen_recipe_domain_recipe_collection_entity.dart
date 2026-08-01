import 'dart:typed_data';

import 'kitchen_recipe_domain_recipe_journal_summary_entity.dart';

/// 菜谱集封面的类型化变更，避免 Feature 接触本地文件路径。
enum RecipeCollectionCoverChangeKind { keep, remove, replace }

/// 编辑菜谱集时请求的封面变更。
class RecipeCollectionCoverChange {
  const RecipeCollectionCoverChange._(this.kind, this.bytes);

  /// 保留当前封面。
  const RecipeCollectionCoverChange.keep()
    : this._(RecipeCollectionCoverChangeKind.keep, null);

  /// 删除当前自定义封面并恢复内置书封。
  const RecipeCollectionCoverChange.remove()
    : this._(RecipeCollectionCoverChangeKind.remove, null);

  /// 使用已经裁切、压缩后的 JPEG 字节替换封面。
  RecipeCollectionCoverChange.replace(Uint8List bytes)
    : this._(RecipeCollectionCoverChangeKind.replace, bytes);

  /// 本次变更的稳定类型。
  final RecipeCollectionCoverChangeKind kind;

  /// 替换封面的 JPEG 字节；保留或删除时为空。
  final Uint8List? bytes;
}

/// 菜谱集列表中的领域摘要。
class RecipeCollectionEntity {
  const RecipeCollectionEntity({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.coverBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 菜谱集唯一标识。
  final String id;

  /// 去除首尾空格后的菜谱集名称；允许与其他集合重名。
  final String name;

  /// 当前未删除成员数量。
  final int memberCount;

  /// 已裁切的自定义 JPEG 封面；未设置、损坏或读取失败时为空。
  final Uint8List? coverBytes;

  /// 菜谱集首次创建时间。
  final DateTime createdAt;

  /// 名称、顺序或成员最近变更时间。
  final DateTime updatedAt;
}

/// 菜谱集中的成员摘要。
class RecipeCollectionMemberEntity {
  const RecipeCollectionMemberEntity({
    required this.recipe,
    required this.addedAt,
    required this.position,
  });

  /// 成员菜谱的手账摘要。
  final RecipeJournalSummaryEntity recipe;

  /// 菜谱加入当前集合的时间，用于详情默认排序。
  final DateTime addedAt;

  /// 成员在集合内的零基稳定位置；软删除菜谱不会改变该位置。
  final int position;
}

/// 菜谱集详情及其有效成员。
class RecipeCollectionDetailEntity {
  const RecipeCollectionDetailEntity({
    required this.collection,
    required this.members,
  });

  /// 当前菜谱集摘要。
  final RecipeCollectionEntity collection;

  /// 未删除成员，按集合内位置升序排列。
  final List<RecipeCollectionMemberEntity> members;
}

/// 校验并标准化菜谱集名称。
String normalizeRecipeCollectionName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'name', '菜谱集名称不能为空');
  }
  if (normalized.runes.length > 40) {
    throw ArgumentError.value(value, 'name', '菜谱集名称最多 40 个字');
  }
  return normalized;
}
