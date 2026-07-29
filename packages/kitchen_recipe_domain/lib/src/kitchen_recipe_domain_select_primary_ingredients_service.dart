import 'kitchen_recipe_domain_ingredient_entity.dart';
import 'kitchen_recipe_domain_ingredient_summary_value_object.dart';

class SelectPrimaryIngredientsService {
  const SelectPrimaryIngredientsService();

  List<IngredientSummaryValueObject> call({
    required List<IngredientEntity> ingredients,
    int limit = 4,
  }) {
    if (limit <= 0) return const [];

    final sorted = [...ingredients]
      // 手账摘要与详情共用用户维护的唯一食材顺序，避免出现隐式重排。
      ..sort((left, right) => left.position.compareTo(right.position));

    return sorted
        .take(limit)
        .map(
          (ingredient) => IngredientSummaryValueObject(
            name: ingredient.name,
            amountText: ingredient.amountText,
          ),
        )
        .toList(growable: false);
  }
}
