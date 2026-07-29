import 'kitchen_recipe_domain_recipe_template_selection_value_object.dart';

class CreateRecipeInput {
  const CreateRecipeInput({
    required this.title,
    required this.summary,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.templateSelection,
  });

  /// 用户输入的菜谱名称；保存前会去除首尾空白并校验长度。
  final String title;

  /// 菜谱的简短介绍；允许为空。
  final String summary;

  /// 菜谱所属的唯一主分类。
  final String category;

  /// 用户逐行输入的食材文本，顺序即保存后的展示顺序。
  final List<String> ingredients;

  /// 用户逐行输入的烹饪步骤，顺序即实际执行顺序。
  final List<String> steps;

  /// 本菜谱选用的模板 ID 与版本。
  final RecipeTemplateSelectionValueObject templateSelection;
}
