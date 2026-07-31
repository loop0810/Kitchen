import 'kitchen_recipe_domain_parsed_ingredient_value_object.dart';

class IngredientLineParserService {
  const IngredientLineParserService();

  ParsedIngredientValueObject call(String line) {
    // 先只去除行尾空白，保留“名称被删掉后剩下的分隔空格”。例如用户把
    // “鸡蛋  2 个”中的“鸡蛋”删掉时，应解析为空名称，而不是“2 个 + 适量”。
    final normalized = line.trimRight();
    // 导入内容偶尔沿用网页视觉顺序“用量 + 食材”。即使上游未完成
    // 规范化，这里也要保证预览与最终保存获得正确的名称和用量。
    final leadingAmount = RegExp(
      r'^(\d+(?:\.\d+)?\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张))\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(normalized.trim());
    if (leadingAmount != null) {
      return ParsedIngredientValueObject(
        name: leadingAmount.group(2)!.trim(),
        amountText: leadingAmount.group(1)!.trim(),
      );
    }

    // 优先处理用户提示中最明确的“双空格/冒号”格式，如“番茄  2 个”。
    final separator = RegExp(r'\s{2,}|[：:]');
    final parts = normalized.split(separator);
    if (parts.length > 1) {
      return ParsedIngredientValueObject(
        name: parts.first.trim(),
        amountText: parts.sublist(1).join(' ').trim(),
      );
    }

    // 单空格可能同时出现在食材名中，因此只在尾部像用量时才拆分。
    final match = RegExp(
      r'^(.+?)\s+([\d.]+.*|适量|少许|一小把|半[个碗勺杯])$',
    ).firstMatch(normalized);
    if (match != null) {
      return ParsedIngredientValueObject(
        name: match.group(1)!,
        amountText: match.group(2)!,
      );
    }

    // OCR、网页元数据和中文自然输入经常省略名称与用量之间的空格，例如
    // “鸡腿1个”“盐少许”。只匹配明确的单位或自然语言用量，避免猜测普通词尾。
    final attachedAmount = RegExp(
      r'^(.+?)([\d.]+\s*(?:千克|公斤|毫升|大勺|小勺|克|g|kg|ml|斤|两|个|只|勺|片|杯|根|颗|块|罐|瓶|瓣|条|枚|盒|袋|滴|撮|把|朵|段|张)|适量|少许)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (attachedAmount != null) {
      return ParsedIngredientValueObject(
        name: attachedAmount.group(1)!.trim(),
        amountText: attachedAmount.group(2)!.trim(),
      );
    }

    // 无法可靠判断用量时保留完整名称，并使用产品约定的默认用量。
    return ParsedIngredientValueObject(
      name: normalized.trim(),
      amountText: '适量',
    );
  }
}
