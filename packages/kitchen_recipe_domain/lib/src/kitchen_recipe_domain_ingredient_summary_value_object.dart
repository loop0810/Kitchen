class IngredientSummaryValueObject {
  const IngredientSummaryValueObject({
    required this.name,
    required this.amountText,
  });

  /// 摘要中展示的食材名称。
  final String name;

  /// 摘要中展示的用量文本。
  final String amountText;
}
