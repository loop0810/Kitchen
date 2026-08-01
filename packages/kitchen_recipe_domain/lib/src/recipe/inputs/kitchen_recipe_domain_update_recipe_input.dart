import '../../template/value_objects/kitchen_recipe_domain_recipe_template_selection_value_object.dart';

class UpdateRecipeIngredientInput {
  const UpdateRecipeIngredientInput({
    required this.id,
    required this.name,
    required this.amountText,
    required this.amountValue,
    required this.unit,
    required this.preparation,
    required this.isOptional,
  });

  /// 已有食材的稳定 ID；新增食材为空并由 Repository 生成。
  final String? id;

  /// 食材名称，例如“番茄”。
  final String name;

  /// 面向用户展示的用量文本，例如“2 个”或“适量”。
  final String amountText;

  /// 原有的结构化用量数值；当前编辑器未展示时仍原样保留。
  final double? amountValue;

  /// 原有的结构化单位；当前编辑器未展示时仍原样保留。
  final String? unit;

  /// 原有的预处理说明；当前编辑器未展示时仍原样保留。
  final String? preparation;

  /// 是否为可省略食材；当前编辑器未展示时仍原样保留。
  final bool isOptional;
}

class UpdateRecipeStepInput {
  const UpdateRecipeStepInput({
    required this.id,
    required this.title,
    required this.instruction,
    required this.durationMinutes,
    required this.heatLevel,
  });

  /// 已有步骤的稳定 ID；新增步骤为空并由 Repository 生成。
  final String? id;

  /// 原有步骤小标题；当前编辑器未展示时仍原样保留。
  final String? title;

  /// 用户实际阅读和执行的步骤说明。
  final String instruction;

  /// 原有预计时长，单位为分钟；当前编辑器未展示时仍原样保留。
  final int? durationMinutes;

  /// 原有火力描述；当前编辑器未展示时仍原样保留。
  final String? heatLevel;
}

class UpdateRecipeInput {
  const UpdateRecipeInput({
    required this.recipeId,
    required this.title,
    required this.summary,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.templateSelection,
  });

  /// 要更新的菜谱 ID。
  final String recipeId;

  /// 用户输入的菜谱名称；保存前会去除首尾空白并校验长度。
  final String title;

  /// 菜谱的简短介绍；允许为空。
  final String summary;

  /// 菜谱所属的唯一主分类。
  final String category;

  /// 按最新展示顺序排列的食材；已有条目通过稳定 ID 保留扩展数据。
  final List<UpdateRecipeIngredientInput> ingredients;

  /// 按最新执行顺序排列的步骤；已有条目通过稳定 ID 保留扩展数据。
  final List<UpdateRecipeStepInput> steps;

  /// 本菜谱最新选用的模板 ID 与版本。
  final RecipeTemplateSelectionValueObject templateSelection;
}
