enum RecipeStatusFilter { all, favorite, cooked, incomplete }

class RecipeQuery {
  const RecipeQuery({
    this.text = '',
    this.statusFilter = RecipeStatusFilter.all,
  });

  /// 本地搜索文字；空字符串表示不限制关键词。
  final String text;

  /// 菜谱库快捷状态筛选条件。
  final RecipeStatusFilter statusFilter;

  // Riverpod family 使用相等性判断参数是否代表同一份缓存，因此这里必须按值比较。
  @override
  bool operator ==(Object other) =>
      other is RecipeQuery &&
      other.text == text &&
      other.statusFilter == statusFilter;

  @override
  int get hashCode => Object.hash(text, statusFilter);
}
