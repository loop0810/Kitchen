enum RecipeStatusFilter { all, favorite, cooked, incomplete }

/// 菜谱库支持的稳定排序方式。
enum RecipeSortOrder {
  recentlyUpdated,
  recentlySaved,
  recentlyCooked,
  mostCooked,
  title,
}

/// 列表查询的数据范围，避免页面用生命周期字符串拼装查询。
enum RecipeListScope { library, trash }

class RecipeQuery {
  const RecipeQuery({
    this.text = '',
    this.statusFilter = RecipeStatusFilter.all,
    this.sortOrder = RecipeSortOrder.recentlyUpdated,
    this.scope = RecipeListScope.library,
  });

  /// 本地搜索文字；空字符串表示不限制关键词。
  final String text;

  /// 菜谱库快捷状态筛选条件。
  final RecipeStatusFilter statusFilter;

  /// 当前列表采用的排序方式。
  final RecipeSortOrder sortOrder;

  /// 当前查询属于默认菜谱库还是回收站。
  final RecipeListScope scope;

  // Riverpod family 使用相等性判断参数是否代表同一份缓存，因此这里必须按值比较。
  @override
  bool operator ==(Object other) =>
      other is RecipeQuery &&
      other.text == text &&
      other.statusFilter == statusFilter &&
      other.sortOrder == sortOrder &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(text, statusFilter, sortOrder, scope);
}
