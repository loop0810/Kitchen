import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  test('重新结构化只更新自动字段并保护用户列表', () {
    final current = _draft(
      title: const DraftFieldValue(
        value: '我的番茄炒蛋',
        origin: DraftFieldOrigin.userConfirmed,
      ),
      ingredients: const DraftFieldValue(
        value: ['番茄 3个', '鸡蛋 2个'],
        origin: DraftFieldOrigin.userEdited,
      ),
    );
    final candidate = _draft(
      title: const DraftFieldValue(
        value: '番茄炒蛋',
        origin: DraftFieldOrigin.source,
      ),
      summary: const DraftFieldValue(
        value: '新摘要',
        origin: DraftFieldOrigin.inferred,
      ),
      ingredients: const DraftFieldValue(
        value: ['番茄 2个'],
        origin: DraftFieldOrigin.source,
      ),
    );

    final merged = const RecipeDraftMergeService().merge(
      current: current,
      candidate: candidate,
    );

    expect(merged.title.value, '我的番茄炒蛋');
    expect(merged.title.conflictCandidate, '番茄炒蛋');
    expect(merged.summary.value, '新摘要');
    expect(merged.ingredients.value, ['番茄 3个', '鸡蛋 2个']);
    expect(merged.ingredients.conflictCandidate, ['番茄 2个']);
  });
}

RecipeDraftEntity _draft({
  DraftFieldValue<String>? title,
  DraftFieldValue<String>? summary,
  DraftFieldValue<List<String>>? ingredients,
}) {
  return RecipeDraftEntity(
    title:
        title ??
        const DraftFieldValue(value: '旧菜名', origin: DraftFieldOrigin.inferred),
    summary:
        summary ??
        const DraftFieldValue(value: '旧摘要', origin: DraftFieldOrigin.inferred),
    category: const DraftFieldValue(
      value: '家常菜',
      origin: DraftFieldOrigin.inferred,
    ),
    servings: const DraftFieldValue(
      value: null,
      origin: DraftFieldOrigin.inferred,
    ),
    prepMinutes: const DraftFieldValue(
      value: null,
      origin: DraftFieldOrigin.inferred,
    ),
    cookMinutes: const DraftFieldValue(
      value: null,
      origin: DraftFieldOrigin.inferred,
    ),
    difficulty: const DraftFieldValue(
      value: '',
      origin: DraftFieldOrigin.inferred,
    ),
    tags: const DraftFieldValue(value: [], origin: DraftFieldOrigin.inferred),
    ingredients:
        ingredients ??
        const DraftFieldValue(value: [], origin: DraftFieldOrigin.inferred),
    steps: const DraftFieldValue(value: [], origin: DraftFieldOrigin.inferred),
    sourceSnapshot: const SourceSnapshot(originalText: ''),
  );
}
