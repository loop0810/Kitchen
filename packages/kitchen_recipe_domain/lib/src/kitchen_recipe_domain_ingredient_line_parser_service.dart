import 'kitchen_recipe_domain_parsed_ingredient_value_object.dart';

class IngredientLineParserService {
  const IngredientLineParserService();

  ParsedIngredientValueObject call(String line) {
    final normalized = line.trim();
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

    // 无法可靠判断用量时保留完整名称，并使用产品约定的默认用量。
    return ParsedIngredientValueObject(name: normalized, amountText: '适量');
  }
}
