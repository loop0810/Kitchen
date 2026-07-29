import 'kitchen_recipe_domain_ingredient_entity.dart';
import 'kitchen_recipe_domain_ingredient_group_entity.dart';
import 'kitchen_recipe_domain_ingredient_summary_value_object.dart';

class SelectPrimaryIngredientsService {
  const SelectPrimaryIngredientsService();

  static const _seasoningGroupNames = {'调料', '调味料', '蘸料', '酱汁'};

  List<IngredientSummaryValueObject> call({
    required List<IngredientGroupEntity> groups,
    required List<IngredientEntity> ingredients,
    int limit = 4,
  }) {
    if (limit <= 0) return const [];

    final groupsById = {for (final group in groups) group.id: group};
    final sorted = [...ingredients]
      ..sort((left, right) {
        final leftGroup = groupsById[left.groupId];
        final rightGroup = groupsById[right.groupId];
        final leftIsSeasoning = _isSeasoning(leftGroup);
        final rightIsSeasoning = _isSeasoning(rightGroup);
        if (leftIsSeasoning != rightIsSeasoning) {
          return leftIsSeasoning ? 1 : -1;
        }

        final groupComparison = (leftGroup?.position ?? -1).compareTo(
          rightGroup?.position ?? -1,
        );
        if (groupComparison != 0) return groupComparison;
        return left.position.compareTo(right.position);
      });

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

  bool _isSeasoning(IngredientGroupEntity? group) {
    return group != null && _seasoningGroupNames.contains(group.name.trim());
  }
}
