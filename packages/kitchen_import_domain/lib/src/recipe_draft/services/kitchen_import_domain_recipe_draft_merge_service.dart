import '../entities/kitchen_import_domain_recipe_draft_entity.dart';

/// 将重新结构化的自动候选保守合并到用户审核草稿。
///
/// 用户编辑或确认的字段是保护边界。对食材、步骤和标签等列表，
/// 保护粒度是整个列表，避免重新识别打乱用户已调整的顺序。
class RecipeDraftMergeService {
  const RecipeDraftMergeService();

  RecipeDraftEntity merge({
    required RecipeDraftEntity current,
    required RecipeDraftEntity candidate,
  }) {
    return RecipeDraftEntity(
      schemaVersion: candidate.schemaVersion,
      quality: candidate.quality,
      warnings: candidate.warnings,
      title: _mergeField(current.title, candidate.title),
      summary: _mergeField(current.summary, candidate.summary),
      category: _mergeField(current.category, candidate.category),
      servings: _mergeField(current.servings, candidate.servings),
      prepMinutes: _mergeField(current.prepMinutes, candidate.prepMinutes),
      cookMinutes: _mergeField(current.cookMinutes, candidate.cookMinutes),
      difficulty: _mergeField(current.difficulty, candidate.difficulty),
      tags: _mergeField(current.tags, candidate.tags),
      ingredients: _mergeField(current.ingredients, candidate.ingredients),
      preparations: _mergeField(current.preparations, candidate.preparations),
      steps: _mergeField(current.steps, candidate.steps),
      sourceSnapshot: candidate.sourceSnapshot,
    );
  }

  DraftFieldValue<T> _mergeField<T>(
    DraftFieldValue<T> current,
    DraftFieldValue<T> candidate,
  ) {
    final protected =
        current.origin == DraftFieldOrigin.userEdited ||
        current.origin == DraftFieldOrigin.userConfirmed;
    if (!protected) return candidate;
    return DraftFieldValue<T>(
      value: current.value,
      origin: current.origin,
      needsConfirmation: current.needsConfirmation,
      confidence: current.confidence,
      evidence: current.evidence,
      conflictCandidate: _sameValue(current.value, candidate.value)
          ? null
          : candidate.value,
    );
  }

  bool _sameValue(Object? left, Object? right) {
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_sameValue(left[index], right[index])) return false;
      }
      return true;
    }
    return left == right;
  }
}
