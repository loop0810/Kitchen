class TemplateIngredientData {
  const TemplateIngredientData({required this.name, required this.amountText});

  final String name;
  final String amountText;
}

class TemplateRenderData {
  const TemplateRenderData({
    required this.title,
    required this.primaryIngredients,
    required this.category,
    required this.totalMinutes,
    required this.isIncomplete,
  });

  final String title;
  final List<TemplateIngredientData> primaryIngredients;
  final String category;
  final int? totalMinutes;
  final bool isIncomplete;
}

enum TemplateRenderMode { thumbnail, reader }
