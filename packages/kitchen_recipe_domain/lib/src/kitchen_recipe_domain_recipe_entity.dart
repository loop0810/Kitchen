enum RecipeStatus { incomplete, ready, archived, deleted }

class RecipeEntity {
  const RecipeEntity({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    required this.presentationStyle,
    required this.isFavorite,
    required this.lastCookedAt,
    required this.cookCount,
    required this.status,
    required this.coverColor,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String category;
  final int? servings;
  final int? prepMinutes;
  final int? cookMinutes;
  final String difficulty;
  final String presentationStyle;
  final bool isFavorite;
  final DateTime? lastCookedAt;
  final int cookCount;
  final RecipeStatus status;
  final int coverColor;
  final DateTime createdAt;
  final DateTime updatedAt;
}
