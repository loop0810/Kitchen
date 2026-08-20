import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

import '../providers/kitchen_recipe_editor_dependencies.dart';

class RecipeEditorFormWidget extends ConsumerStatefulWidget {
  const RecipeEditorFormWidget({
    super.key,
    this.initialDetail,
    this.initialInput,
    this.onCreated,
  });

  /// 编辑模式下的完整初始快照；为空时表示创建模式。
  final RecipeDetailEntity? initialDetail;

  /// 导入确认模式下的结构化初始值；普通创建时为空。
  final CreateRecipeInput? initialInput;

  /// 创建成功后的跨 Feature 协调回调；普通创建时为空。
  final Future<void> Function(String recipeId)? onCreated;

  @override
  ConsumerState<RecipeEditorFormWidget> createState() =>
      _RecipeEditorFormWidgetState();
}

class _RecipeEditorFormWidgetState
    extends ConsumerState<RecipeEditorFormWidget> {
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _stepsController;
  late String _category;
  late RecipeTemplateSelectionValueObject _templateSelection;
  late List<_IngredientEditItem> _ingredientItems;
  late List<_StepEditItem> _stepItems;
  var _saving = false;
  var _dirty = false;
  var _allowPop = false;
  String? _titleError;
  String? _categoryError;
  String? _templateError;

  bool get _isEditing => widget.initialDetail != null;

  @override
  void initState() {
    super.initState();
    final detail = widget.initialDetail;
    final initialInput = widget.initialInput;
    _titleController = TextEditingController(
      text: detail?.recipe.title ?? initialInput?.title ?? '',
    );
    _summaryController = TextEditingController(
      text: detail?.recipe.summary ?? initialInput?.summary ?? '',
    );
    _ingredientItems =
        detail?.ingredients
            .map(_IngredientEditItem.fromEntity)
            .toList(growable: true) ??
        initialInput?.ingredients
            .map(_IngredientEditItem.newItem)
            .toList(growable: true) ??
        [];
    _stepItems =
        detail?.steps.map(_StepEditItem.fromEntity).toList(growable: true) ??
        initialInput?.steps.map(_StepEditItem.newItem).toList(growable: true) ??
        [];
    _ingredientsController = TextEditingController(
      text: _ingredientItems.map((item) => item.line).join('\n'),
    );
    _stepsController = TextEditingController(
      text: _stepItems.map((item) => item.line).join('\n'),
    );
    _category = detail?.recipe.category ?? initialInput?.category ?? '';
    _templateSelection =
        detail?.recipe.templateSelection ??
        initialInput?.templateSelection ??
        BuiltInTemplates.defaultSelection;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  List<String> _linesOf(TextEditingController controller) {
    return controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> get _ingredientLines {
    const parser = IngredientLineParserService();
    return _ingredientsController.text
        .split('\n')
        .where((line) => parser(line).name.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList(growable: false);
  }

  void _markDirty() {
    // 预览依赖控制器当前文本；即使表单已经是 dirty，后续每次输入也必须重建。
    setState(() => _dirty = true);
  }

  void _ingredientsChanged(String _) {
    setState(() {
      final reconciled = _reconcileItems<_IngredientEditItem>(
        oldItems: _ingredientItems,
        newLines: _ingredientLines,
        lineOf: (item) => item.line,
        create: _IngredientEditItem.newItem,
        withLine: (item, line) => item.withLine(line),
      );
      _ingredientItems = reconciled;
      _dirty = true;
    });
  }

  void _stepsChanged(String _) {
    setState(() {
      _stepItems = _reconcileItems<_StepEditItem>(
        oldItems: _stepItems,
        newLines: _linesOf(_stepsController),
        lineOf: (item) => item.line,
        create: _StepEditItem.newItem,
        withLine: (item, line) => item.withLine(line),
      );
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final createInput = _createInput;
    // 页面先校验一次以立即标记字段；UseCase 内仍会再次校验，防止其他入口绕过规则。
    final validationFailure = const CreateRecipeValidationService()(
      createInput,
    );
    if (validationFailure != null) {
      _applyValidationFailure(validationFailure);
      return;
    }
    setState(() {
      _titleError = null;
      _categoryError = null;
      _templateError = null;
      _saving = true;
    });
    try {
      final dependencies = ref.read(recipeEditorDependenciesProvider);
      if (_isEditing) {
        await dependencies.updateRecipe(_updateInput);
        if (mounted) {
          _allowPop = true;
          Navigator.of(context).pop(true);
        }
      } else {
        final id = await dependencies.createRecipe(createInput);
        await widget.onCreated?.call(id);
        // await 期间用户可能已经退出页面；mounted 防止继续使用已销毁的 context。
        if (mounted) {
          _allowPop = true;
          context.replaceWithRecipeDetail(id);
        }
      }
    } on CreateRecipeValidationFailure catch (failure) {
      if (mounted) _applyValidationFailure(failure);
    } catch (error, stackTrace) {
      developer.log(
        _isEditing ? 'update_recipe_failed' : 'create_recipe_failed',
        name: 'kitchen_recipe_editor',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? '更新失败，请稍后重试' : '保存失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyValidationFailure(CreateRecipeValidationFailure failure) {
    setState(() {
      _titleError = failure.errorFor(CreateRecipeValidationField.title);
      _categoryError = failure.errorFor(CreateRecipeValidationField.category);
      _templateError = failure.errorFor(CreateRecipeValidationField.template);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.firstError)));
  }

  Future<void> _confirmDiscard() async {
    if (_saving) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃未保存的修改？'),
        content: const Text('当前输入尚未保存，离开后将无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final personalConfig =
        ref.watch(recipeEditorPersonalRecipeConfigProvider).valueOrNull ??
        PersonalRecipeConfigEntity.defaults;
    final selectedCategory = _resolvedCategory(personalConfig);
    final categoryOptions = [
      ...personalConfig.categories,
      if (selectedCategory.isNotEmpty &&
          !personalConfig.categories.contains(selectedCategory))
        selectedCategory,
    ];
    return PopScope(
      canPop: _allowPop || !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _dirty) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '编辑菜谱' : '创建菜谱'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('保存'),
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s32,
          ),
          children: [
            _Section(
              title: '基本信息',
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {
                      _titleError = null;
                      _dirty = true;
                    }),
                    decoration: InputDecoration(
                      labelText: '菜名 *',
                      hintText: '例如：番茄炒蛋',
                      errorText: _titleError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  TextFormField(
                    controller: _summaryController,
                    onChanged: (_) => _markDirty(),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '简介',
                      hintText: '这道菜有什么特别之处？',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory.isEmpty
                        ? null
                        : selectedCategory,
                    decoration: InputDecoration(
                      labelText: '主分类',
                      errorText: _categoryError,
                    ),
                    items: categoryOptions
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _category = value ?? _category;
                      _categoryError = null;
                      _dirty = true;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _Section(
              title: '食材',
              subtitle: '每行一种，名称和用量用空格或冒号分隔',
              child: TextFormField(
                controller: _ingredientsController,
                onChanged: _ingredientsChanged,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '番茄  2 个\n鸡蛋  3 个\n盐  适量',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _Section(
              title: '手账预览',
              subtitle: '缩略图最多展示前 4 项食材，完整食材会保留在详情中',
              child: Center(
                child: Column(
                  children: [
                    DropdownButtonFormField<RecipeTemplateSelectionValueObject>(
                      initialValue: _templateResolution.usedFallback
                          ? BuiltInTemplates.defaultSelection
                          : _templateSelection,
                      decoration: InputDecoration(
                        labelText: '手账模板',
                        errorText: _templateError,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: BuiltInTemplates.defaultSelection,
                          child: Text('基础手账'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _templateSelection =
                            value ?? BuiltInTemplates.defaultSelection;
                        _templateError = null;
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SizedBox(
                      width: 220,
                      child: RecipeTemplateRendererWidget(
                        definition: _templateResolution.definition,
                        data: _templateRenderData,
                        mode: TemplateRenderMode.reader,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _Section(
              title: '步骤',
              subtitle: '每行一个步骤，保存后可以继续完善',
              child: TextFormField(
                controller: _stepsController,
                onChanged: _stepsChanged,
                minLines: 6,
                maxLines: 14,
                decoration: const InputDecoration(
                  hintText: '番茄切块，鸡蛋打散。\n先将鸡蛋炒至凝固后盛出。\n炒软番茄，再放回鸡蛋。',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: AppSize.icon18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? '正在保存…' : (_isEditing ? '保存修改' : '保存菜谱')),
            ),
          ],
        ),
      ),
    );
  }

  String _resolvedCategory(PersonalRecipeConfigEntity config) {
    if (_category.isNotEmpty) return _category;
    return config.categories.isEmpty ? '' : config.categories.first;
  }

  String get _currentCategory {
    final config =
        ref.read(recipeEditorPersonalRecipeConfigProvider).valueOrNull ??
        PersonalRecipeConfigEntity.defaults;
    return _resolvedCategory(config);
  }

  CreateRecipeInput get _createInput {
    return CreateRecipeInput(
      title: _titleController.text,
      summary: _summaryController.text,
      category: _currentCategory,
      ingredients: _ingredientLines,
      steps: _linesOf(_stepsController),
      templateSelection: _templateSelection,
      servings: widget.initialInput?.servings,
      prepMinutes: widget.initialInput?.prepMinutes,
      cookMinutes: widget.initialInput?.cookMinutes,
      difficulty: widget.initialInput?.difficulty ?? '',
      tags: widget.initialInput?.tags ?? const [],
      sourceSnapshot: widget.initialInput?.sourceSnapshot,
      importTaskId: widget.initialInput?.importTaskId,
    );
  }

  UpdateRecipeInput get _updateInput {
    const parser = IngredientLineParserService();
    return UpdateRecipeInput(
      recipeId: widget.initialDetail!.recipe.id,
      title: _titleController.text,
      summary: _summaryController.text,
      category: _currentCategory,
      ingredients: _ingredientItems
          .map((item) {
            final parsed = parser(item.line);
            return UpdateRecipeIngredientInput(
              id: item.id,
              name: parsed.name,
              amountText: parsed.amountText,
              amountValue: item.amountValue,
              unit: item.unit,
              preparation: item.preparation,
              isOptional: item.isOptional,
            );
          })
          .toList(growable: false),
      steps: _stepItems
          .map(
            (item) => UpdateRecipeStepInput(
              id: item.id,
              title: item.title,
              instruction: item.line,
              durationMinutes: item.durationMinutes,
              heatLevel: item.heatLevel,
            ),
          )
          .toList(growable: false),
      templateSelection: _templateSelection,
    );
  }

  TemplateResolution get _templateResolution {
    return BuiltInTemplates.defaultResolver(_templateSelection);
  }

  TemplateRenderData get _templateRenderData {
    const parser = IngredientLineParserService();
    // 预览与最终保存共用同一个领域解析器，避免用户看到的结果和落库结果不一致。
    final ingredients = _ingredientsController.text
        .split('\n')
        .map(parser.call)
        .where((ingredient) => ingredient.name.trim().isNotEmpty)
        .take(4)
        .map(
          (ingredient) => TemplateIngredientData(
            name: ingredient.name,
            amountText: ingredient.amountText,
          ),
        )
        .toList(growable: false);
    return TemplateRenderData(
      title: _titleController.text.trim().isEmpty
          ? '菜名待补充'
          : _titleController.text.trim(),
      primaryIngredients: ingredients,
      category: _currentCategory,
      totalMinutes: null,
      isIncomplete: ingredients.isEmpty || _linesOf(_stepsController).isEmpty,
    );
  }
}

List<T> _reconcileItems<T>({
  required List<T> oldItems,
  required List<String> newLines,
  required String Function(T item) lineOf,
  required T Function(String line) create,
  required T Function(T item, String line) withLine,
}) {
  final unused = oldItems.toSet();
  final matches = List<T?>.filled(newLines.length, null);

  // 先为未修改或被重新排序的文本保留原条目，再处理就地修改。这样在列表开头
  // 新增一行时，不会错误地把第一条旧记录的稳定 ID 转移给新内容。
  for (final (index, line) in newLines.indexed) {
    T? exactMatch;
    for (final item in unused) {
      if (lineOf(item) == line) {
        exactMatch = item;
        break;
      }
    }
    if (exactMatch != null) {
      matches[index] = exactMatch;
      unused.remove(exactMatch);
    }
  }

  final result = <T>[];
  for (final (index, line) in newLines.indexed) {
    var match = matches[index];
    if (match == null && index < oldItems.length) {
      final positional = oldItems[index];
      if (unused.contains(positional)) match = positional;
    }
    if (match == null) {
      result.add(create(line));
    } else {
      unused.remove(match);
      result.add(withLine(match, line));
    }
  }
  return result;
}

class _IngredientEditItem {
  const _IngredientEditItem({
    required this.line,
    required this.id,
    required this.amountValue,
    required this.unit,
    required this.preparation,
    required this.isOptional,
  });

  factory _IngredientEditItem.fromEntity(IngredientEntity ingredient) {
    return _IngredientEditItem(
      line: '${ingredient.name}  ${ingredient.amountText}',
      id: ingredient.id,
      amountValue: ingredient.amountValue,
      unit: ingredient.unit,
      preparation: ingredient.preparation,
      isOptional: ingredient.isOptional,
    );
  }

  factory _IngredientEditItem.newItem(String line) {
    return _IngredientEditItem(
      line: line,
      id: null,
      amountValue: null,
      unit: null,
      preparation: null,
      isOptional: false,
    );
  }

  final String line;
  final String? id;
  final double? amountValue;
  final String? unit;
  final String? preparation;
  final bool isOptional;

  _IngredientEditItem withLine(String value) {
    return _IngredientEditItem(
      line: value,
      id: id,
      amountValue: amountValue,
      unit: unit,
      preparation: preparation,
      isOptional: isOptional,
    );
  }
}

class _StepEditItem {
  const _StepEditItem({
    required this.line,
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.heatLevel,
  });

  factory _StepEditItem.fromEntity(RecipeStepEntity step) {
    return _StepEditItem(
      line: step.instruction,
      id: step.id,
      title: step.title,
      durationMinutes: step.durationMinutes,
      heatLevel: step.heatLevel,
    );
  }

  factory _StepEditItem.newItem(String line) {
    return _StepEditItem(
      line: line,
      id: null,
      title: null,
      durationMinutes: null,
      heatLevel: null,
    );
  }

  final String line;
  final String? id;
  final String? title;
  final int? durationMinutes;
  final String? heatLevel;

  _StepEditItem withLine(String value) {
    return _StepEditItem(
      line: value,
      id: id,
      title: title,
      durationMinutes: durationMinutes,
      heatLevel: heatLevel,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s14),
            child,
          ],
        ),
      ),
    );
  }
}
