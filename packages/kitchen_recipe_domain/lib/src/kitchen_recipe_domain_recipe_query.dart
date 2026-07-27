enum RecipeStatusFilter { all, favorite, cooked, incomplete }

class RecipeQuery {
  const RecipeQuery({
    this.text = '',
    this.statusFilter = RecipeStatusFilter.all,
  });

  final String text;
  final RecipeStatusFilter statusFilter;

  @override
  bool operator ==(Object other) =>
      other is RecipeQuery &&
      other.text == text &&
      other.statusFilter == statusFilter;

  @override
  int get hashCode => Object.hash(text, statusFilter);
}
