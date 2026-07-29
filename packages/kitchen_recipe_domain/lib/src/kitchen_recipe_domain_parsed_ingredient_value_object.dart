class ParsedIngredientValueObject {
  const ParsedIngredientValueObject({
    required this.name,
    required this.amountText,
  });

  /// 从一行自然语言中解析出的食材名称。
  final String name;

  /// 从该行解析出的用量文本；无法识别时使用“适量”。
  final String amountText;
}
