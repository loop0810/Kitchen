import 'kitchen_import_domain_import_pipeline.dart';
import 'kitchen_import_domain_recipe_draft_entity.dart';

class LocalRecipeStructurerService implements RecipeStructurer {
  const LocalRecipeStructurerService();

  static final _stepPrefix = RegExp(
    r'^\s*(?:(?:步骤\s*)?(?:\d+|[一二三四五六七八九十]+)[.、:：)\s]+|[0-9]\uFE0F?\u20E3\s*)',
  );
  static final _ingredientSection = RegExp(
    r'^(?:🍳\s*)?(?:食材|用料|材料|配料)(?:清单)?(?:\s*(?:&|＆|和|及|/)\s*(?:做法|步骤|流程))?\s*[:：]?$',
    caseSensitive: false,
  );
  static final _stepSection = RegExp(r'^(?:步骤|流程|做法|制作方法|烹饪步骤|操作步骤)\s*[:：]?$');
  static final _nonRecipeSection = RegExp(
    r'^(?:⚠️?\s*)?(?:tips?|小贴士|注意事项)\s*[:：]?$',
    caseSensitive: false,
  );
  static final _ingredientHint = RegExp(
    r'(?:\d+(?:\.\d+)?\s*(?:克|g|kg|毫升|ml|个|只|勺|片|杯)|适量|少许)',
    caseSensitive: false,
  );

  @override
  RecipeDraftEntity structure({
    required String text,
    required SourceSnapshot source,
  }) {
    final lines = text
        // 微信等富文本来源可能使用 Unicode 行分隔符；在领域边界统一为逻辑行，
        // 避免分区标题与正文粘在同一行而导致整篇内容落入同一字段。
        .split(RegExp(r'(?:\r\n?|[\n\u2028\u2029])+'))
        .map((line) => line.replaceAll('\uFEFF', '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final title = _title(lines);
    final ingredients = <String>[];
    final steps = <String>[];
    var section = '';
    for (final line in lines.skip(title.isEmpty ? 0 : 1)) {
      if (_ingredientSection.hasMatch(line)) {
        section = 'ingredients';
        continue;
      }
      if (_stepSection.hasMatch(line)) {
        section = 'steps';
        continue;
      }
      if (_nonRecipeSection.hasMatch(line)) {
        section = '';
        continue;
      }
      // 明确的步骤编号优先于当前分区，兼容“食材 & 做法”后直接出现步骤、
      // 没有单独“步骤”标题的社交平台文案。
      if (_stepPrefix.hasMatch(line)) {
        section = 'steps';
        steps.add(line.replaceFirst(_stepPrefix, ''));
        continue;
      }
      if (section == 'ingredients' || _ingredientHint.hasMatch(line)) {
        ingredients.addAll(_ingredientLines(line));
      } else if (section == 'steps') {
        steps.add(line);
      }
    }
    return RecipeDraftEntity(
      title: DraftFieldValue(
        value: title,
        origin: DraftFieldOrigin.source,
        needsConfirmation: title.isEmpty,
      ),
      summary: const DraftFieldValue(
        value: '',
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      category: const DraftFieldValue(
        value: '家常菜',
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      servings: const DraftFieldValue(
        value: null,
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      prepMinutes: const DraftFieldValue(
        value: null,
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      cookMinutes: const DraftFieldValue(
        value: null,
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      difficulty: const DraftFieldValue(
        value: '',
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      tags: const DraftFieldValue(
        value: [],
        origin: DraftFieldOrigin.inferred,
        needsConfirmation: true,
      ),
      ingredients: DraftFieldValue(
        value: ingredients,
        origin: DraftFieldOrigin.source,
        needsConfirmation: ingredients.isEmpty,
      ),
      steps: DraftFieldValue(
        value: steps,
        origin: DraftFieldOrigin.source,
        needsConfirmation: steps.isEmpty,
      ),
      sourceSnapshot: source,
    );
  }

  String _title(List<String> lines) {
    if (lines.isEmpty) return '';
    final candidate = lines.first
        .replaceFirst(RegExp(r'^(菜名|标题)[:：]\s*'), '')
        .trim();
    if (candidate.length > 40 || _ingredientHint.hasMatch(candidate)) return '';
    return candidate;
  }

  Iterable<String> _ingredientLines(String line) sync* {
    final cleaned = line.replaceFirst(RegExp(r'^[-•]\s*'), '');
    final segments = cleaned
        .split(RegExp(r'\s*[｜|]\s*'))
        .expand((item) => item.split(RegExp(r'\s+(?=(?:酱汁|料汁|调味汁|腌料)\s*[:：])')))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    for (final segment in segments) {
      // 部分网页的结构化数据采用“2斤鸭掌”“60克生抽”这种用量在前的
      // 展示顺序。编辑器约定始终保存“食材名称 用量”，在导入边界转换，
      // 避免预览把整行误认为食材名并回退为“适量”。
      final leadingAmount = RegExp(
        r'^(\d+(?:\.\d+)?\s*(?:千克|公斤|毫升|大勺|小勺|克|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张))\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(segment);
      if (leadingAmount != null) {
        yield '${leadingAmount.group(2)!.trim()} ${leadingAmount.group(1)!.trim()}';
        continue;
      }

      // 仅拆分由葱、姜、蒜组成的短组合，避免误拆“葱姜水”“蒜蓉酱”等
      // 具有独立含义的复合食材。共享的自然语言用量复制到每一种香料。
      final aromatics = RegExp(
        r'^([葱姜蒜]{2,3})\s*(适量|少许)?$',
      ).firstMatch(segment);
      if (aromatics != null) {
        final names = aromatics.group(1)!.split('');
        if (names.toSet().length == names.length) {
          final amount = aromatics.group(2);
          for (final name in names) {
            yield amount == null ? name : '$name $amount';
          }
          continue;
        }
      }

      final amount = RegExp(
        r'^(.+?)(\d+(?:\.\d+)?\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张)|适量|少许)$',
        caseSensitive: false,
      ).firstMatch(segment);
      yield amount == null
          ? segment
          : '${amount.group(1)!.trim()} ${amount.group(2)!.trim()}';
    }
  }
}
