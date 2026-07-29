import 'kitchen_recipe_domain_parsed_ingredient_value_object.dart';

class IngredientLineParserService {
  const IngredientLineParserService();

  ParsedIngredientValueObject call(String line) {
    final normalized = line.trim();
    final separator = RegExp(r'\s{2,}|[：:]');
    final parts = normalized.split(separator);
    if (parts.length > 1) {
      return ParsedIngredientValueObject(
        name: parts.first.trim(),
        amountText: parts.sublist(1).join(' ').trim(),
      );
    }

    final match = RegExp(
      r'^(.+?)\s+([\d.]+.*|适量|少许|一小把|半[个碗勺杯])$',
    ).firstMatch(normalized);
    if (match != null) {
      return ParsedIngredientValueObject(
        name: match.group(1)!,
        amountText: match.group(2)!,
      );
    }

    return ParsedIngredientValueObject(name: normalized, amountText: '适量');
  }
}
