class TemplateIngredientData {
  const TemplateIngredientData({required this.name, required this.amountText});

  /// 模板摘要中展示的食材名称。
  final String name;

  /// 模板摘要中展示的食材用量文本。
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

  /// 模板标题槽位展示的菜谱名称。
  final String title;

  /// 模板主要食材槽位展示的精简食材列表。
  final List<TemplateIngredientData> primaryIngredients;

  /// 模板分类槽位展示的主分类名称。
  final String category;

  /// 准备与烹饪合计分钟数；资料尚未填写时为空。
  final int? totalMinutes;

  /// 菜谱是否缺少食材或步骤等建议内容。
  final bool isIncomplete;
}

enum TemplateRenderMode { thumbnail, reader }
