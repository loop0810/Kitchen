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
  static final _stepSection = RegExp(
    r'^(?:步骤|流程|做法|制作方法|烹饪步骤|操作步骤)\s*(?:\d+|[一二三四五六七八九十了])?\s*[:：]?$',
  );
  static final _nonRecipeSection = RegExp(
    r'^(?:⚠️?\s*)?(?:tips?|小贴士|注意事项)\s*[:：]?$',
    caseSensitive: false,
  );
  static final _ingredientHint = RegExp(
    r'(?:\d+(?:\.\d+)?\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张)|[一二两三四五六七八九十半]+(?:个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|撮|把|朵|段|张)|适量|少许)',
    caseSensitive: false,
  );
  static final _standaloneStepNumber = RegExp(
    r'^(?:步骤\s*)?(?:[1-9]|1\d|20|[一二三四五六七八九十]+)[.、:：)]?$',
  );
  static final _instructionHint = RegExp(
    r'(?:切|抓匀|腌|下锅|炒|盛出|放入?|倒入?|翻炒|淋|撒|出锅|煎|煮|炖|焖|烤|蒸|搅拌|揉|擀|刷|铺|卷|打散|洗净|烧开|调匀|拌匀|淋热油)',
  );
  static final _instructionStart = RegExp(
    r'^(?:将|把|先|再|然后|接着|最后|加|放|倒|淋|撒|煎|煮|炒|蒸|烤|油热)',
  );
  static final _instructionEnding = RegExp(
    r'(?:炒熟|煮熟|煎熟|烤熟|蒸熟|盛出|出锅|备用|翻炒均匀|抓匀|腌\d*分钟)$',
  );
  static final _nonRecipeLine = RegExp(
    r'^(?:[#＃]\s*)?$|^(?:\d+(?:\.\d+)?(?:万)?|[一二三四五六七八九十][：:]?|[<＞>]|[•·…\.]+|小红书|红书|烹饪模式|交作业|下厨房评分|好极了|挺好|一般)$|^[•·]\s*\d+.*$|^\d{1,2}:\d{2}.*$|^\d+(?:\.\d+)?\s*人做过$|^(?:小红书号|红书号)\s*[:：]?.*|^说点什么.*|^菜谱更新于.*|(?:随便|赶紧|快去|点赞|收藏|评论|关注).*(?:做|起来|吧)?$',
    caseSensitive: false,
  );
  static final _dishNameHint = RegExp(
    r'(?:饭|面|粉|粥|汤|羹|饼|包|糕|吐司|蛋糕|面包|饺子|馄饨|鸡|鸭|鱼|虾|蟹|肉|排骨|豆腐|土豆|茄子|甜品|饮品|酱)$',
  );
  static final _titleMethodHint = RegExp(r'(?:拌|炒|煎|烤|焖|炖|蒸|烧|卤|炸)');
  static final _titleLabelHint = RegExp(r'(?:做法|教程|食谱|家庭版|零失败|0失败)');
  static final _columnAmount = RegExp(
    r'^(?:(?:\d+(?:\.\d+)?|[一二两三四五六七八九十半]+)\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张)|适量|少许)(?:[（(].*[）)])?$',
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
    final lineCounts = <String, int>{};
    final contextualChromeLines = <String>{};
    for (final line in lines) {
      lineCounts.update(line, (count) => count + 1, ifAbsent: () => 1);
    }
    for (var index = 1; index < lines.length; index++) {
      if (lines[index] == '关注') contextualChromeLines.add(lines[index - 1]);
    }
    final titleMatch = _title(lines, lineCounts);
    final title = titleMatch.$1;
    final ingredients = <String>[];
    final steps = <String>[];
    final pendingIngredientNames = <String>[];
    final stepFragments = <String>[];
    var section = '';
    var readingColumnAmounts = false;
    var columnAmountIndex = 0;

    void addIngredient(String value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && !ingredients.contains(normalized)) {
        ingredients.add(normalized);
      }
    }

    void finishIngredientBlock() {
      if (!readingColumnAmounts) {
        for (final name in pendingIngredientNames) {
          if (_columnAmount.hasMatch(name) && ingredients.isNotEmpty) {
            // 普通 OCR 也可能把“番茄 2个”拆成相邻两行；没有“换算”列标题时，
            // 用量归到刚刚出现的食材，而不是作为独立名称保存。
            final previous = ingredients.removeLast();
            addIngredient('$previous ${_normalizeAmountWithNote(name)}');
            continue;
          }
          for (final ingredient in _ingredientLines(name)) {
            addIngredient(ingredient);
          }
        }
      } else if (columnAmountIndex < pendingIngredientNames.length) {
        // 截图可能截断用量列；没有配对到用量的名称仍作为“适量”候选保留，
        // 避免为了格式整齐而静默丢失用户原始内容。
        for (final name in pendingIngredientNames.skip(columnAmountIndex)) {
          addIngredient(name);
        }
      }
      pendingIngredientNames.clear();
      readingColumnAmounts = false;
      columnAmountIndex = 0;
    }

    void finishStep() {
      final value = stepFragments.join().trim();
      if (value.isNotEmpty && !steps.contains(value)) steps.add(value);
      stepFragments.clear();
    }

    for (final (index, line) in lines.indexed) {
      if (index == titleMatch.$2) continue;
      if (_ingredientSection.hasMatch(line)) {
        finishIngredientBlock();
        finishStep();
        section = 'ingredients';
        continue;
      }
      if (_stepSection.hasMatch(line)) {
        finishIngredientBlock();
        finishStep();
        section = 'steps';
        continue;
      }
      if (_nonRecipeSection.hasMatch(line)) {
        finishIngredientBlock();
        finishStep();
        section = '';
        continue;
      }
      if (section == 'ingredients' && line == '换算') {
        readingColumnAmounts = true;
        continue;
      }
      if (section == 'steps' && _standaloneStepNumber.hasMatch(line)) {
        // 有些 OCR 会把步骤序号与正文拆成两行；序号同时承担上一条步骤的边界。
        finishStep();
        continue;
      }
      if (_isNoiseLine(line, contextualChromeLines)) continue;
      // 明确的步骤编号优先于当前分区，兼容“食材 & 做法”后直接出现步骤、
      // 没有单独“步骤”标题的社交平台文案。
      if (_stepPrefix.hasMatch(line)) {
        finishIngredientBlock();
        finishStep();
        section = 'steps';
        stepFragments.add(line.replaceFirst(_stepPrefix, ''));
        continue;
      }
      if (section.isEmpty && _looksLikeInstruction(line)) {
        // 无“步骤”标题的短视频拼图里，做法句也经常带“1 勺”等用量。
        // 动作语义必须优先，否则整句会被误当成食材名称。
        steps.add(line);
      } else if (section == 'ingredients' && readingColumnAmounts) {
        if (_columnAmount.hasMatch(line) &&
            columnAmountIndex < pendingIngredientNames.length) {
          final name = pendingIngredientNames[columnAmountIndex++];
          addIngredient('$name ${_normalizeAmountWithNote(line)}');
        }
      } else if (section == 'ingredients') {
        // 下厨房的用料表是左右两列，Vision 通常先返回全部名称，再返回“换算”
        // 和全部用量。暂存名称，直到确认是双列布局或离开用料分区。
        pendingIngredientNames.add(line);
      } else if (section == 'steps') {
        stepFragments.add(line);
      } else if (_ingredientHint.hasMatch(line)) {
        ingredients.addAll(_ingredientLines(line));
      }
    }
    finishIngredientBlock();
    finishStep();
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

  (String, int) _title(List<String> lines, Map<String, int> lineCounts) {
    // OCR 返回顺序主要受文本块坐标影响，短视频标题可能位于食材之后。这里对
    // 所有候选评分：显式标题和话题最高，首行、菜名后缀及烹饪方式作为弱信号；
    // 用量、动作句和平台噪声直接排除，避免再次依赖“第一行就是菜名”。
    var bestValue = '';
    var bestIndex = -1;
    var bestScore = -1;
    for (final (index, rawLine) in lines.indexed) {
      final explicitTitle = RegExp(
        r'^(?:菜名|标题)[:：]\s*(.+)$',
      ).firstMatch(rawLine);
      final hasTopicPrefix = RegExp(r'^[#＃]+\s*\S').hasMatch(rawLine);
      final candidate = (explicitTitle?.group(1) ?? rawLine)
          .replaceFirst(RegExp(r'^[#＃]+\s*'), '')
          .trim();
      if (candidate.isEmpty ||
          candidate.length > 40 ||
          _ingredientHint.hasMatch(candidate) ||
          _nonRecipeLine.hasMatch(rawLine) ||
          _looksLikeInstruction(candidate)) {
        continue;
      }

      var score = 0;
      if (explicitTitle != null) score += 100;
      if (hasTopicPrefix) score += 80;
      if (index == 0) score += 30;
      if (candidate.length <= 20) score += 10;
      if (_dishNameHint.hasMatch(candidate)) score += 20;
      if (_titleMethodHint.hasMatch(candidate)) score += 10;
      if (_titleLabelHint.hasMatch(candidate)) score += 50;
      if ((lineCounts[rawLine] ?? 0) >= 3) score -= 60;
      if (score > bestScore) {
        bestScore = score;
        bestValue = candidate;
        bestIndex = index;
      }
    }
    return (bestValue, bestIndex);
  }

  bool _looksLikeInstruction(String line) {
    // 仅有一个“炒”字不足以区分“番茄炒蛋”和做法。动作位于句首、句尾，
    // 或出现在较长/有标点的语句中时，才把它视为步骤。
    if (RegExp(r'^(?:随便|赶紧|快去)').hasMatch(line)) return false;
    if (!_instructionHint.hasMatch(line)) return false;
    return _instructionStart.hasMatch(line) ||
        _instructionEnding.hasMatch(line) ||
        line.length >= 8 ||
        RegExp(r'[，,。；;]').hasMatch(line);
  }

  bool _isNoiseLine(String line, Set<String> contextualChromeLines) {
    if (_nonRecipeLine.hasMatch(line)) return true;
    // 作者昵称没有稳定格式，但在每页都紧邻“关注”；从相邻关系识别比按重复
    // 次数过滤安全，避免误删跨截图重复出现的食材名称或步骤正文。
    return contextualChromeLines.contains(line);
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
        r'^((?:\d+(?:\.\d+)?|[一二两三四五六七八九十半]+)\s*(?:千克|公斤|毫升|大勺|小勺|克|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张))\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(segment);
      if (leadingAmount != null) {
        yield '${leadingAmount.group(2)!.trim()} ${_normalizeAmount(leadingAmount.group(1)!)}';
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
        r'^(.+?)((?:\d+(?:\.\d+)?|[一二两三四五六七八九十半]+)\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张)|适量|少许)$',
        caseSensitive: false,
      ).firstMatch(segment);
      yield amount == null
          ? segment
          : '${amount.group(1)!.trim()} ${_normalizeAmount(amount.group(2)!)}';
    }
  }

  String _normalizeAmount(String value) {
    // 编辑器的通用食材解析器使用阿拉伯数字识别数量；只转换明确的中文数词，
    // 数字用量保留 OCR 原有空格，避免无谓改变用户看到的原文格式。
    final trimmed = value.trim();
    final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
    const numerals = {
      '一': '1',
      '二': '2',
      '两': '2',
      '三': '3',
      '四': '4',
      '五': '5',
      '六': '6',
      '七': '7',
      '八': '8',
      '九': '9',
      '十': '10',
      '半': '半',
    };
    for (final entry in numerals.entries) {
      if (normalized.startsWith(entry.key)) {
        return '${entry.value}${normalized.substring(entry.key.length)}';
      }
    }
    return trimmed;
  }

  String _normalizeAmountWithNote(String value) {
    final noteStart = value.indexOf(RegExp(r'[（(]'));
    if (noteStart < 0) return _normalizeAmount(value);
    return '${_normalizeAmount(value.substring(0, noteStart))}${value.substring(noteStart)}';
  }
}
