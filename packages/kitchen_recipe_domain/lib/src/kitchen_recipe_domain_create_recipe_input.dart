import 'kitchen_recipe_domain_recipe_template_selection_value_object.dart';
import 'kitchen_recipe_domain_recipe_source_snapshot.dart';

class CreateRecipeInput {
  const CreateRecipeInput({
    required this.title,
    required this.summary,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.templateSelection,
    this.servings,
    this.prepMinutes,
    this.cookMinutes,
    this.difficulty = '',
    this.tags = const [],
    this.sourceSnapshot,
    this.importTaskId,
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

  /// 适用人数；普通空白创建或无法推断时为空。
  final int? servings;

  /// 准备时间，单位为分钟；无法推断时为空。
  final int? prepMinutes;

  /// 烹饪时间，单位为分钟；无法推断时为空。
  final int? cookMinutes;

  /// 用户确认后的难度文案；未填写时为空字符串。
  final String difficulty;

  /// 用户确认后的标签，顺序保持输入顺序。
  final List<String> tags;

  /// 导入来源快照；普通手动创建时为空。
  final RecipeSourceSnapshot? sourceSnapshot;

  /// 对应导入任务 ID；普通创建时为空，同一非空 ID 只能生成一道菜谱。
  final String? importTaskId;
}
