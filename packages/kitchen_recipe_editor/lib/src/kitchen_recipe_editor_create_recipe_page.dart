import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

import 'kitchen_recipe_editor_dependencies.dart';

class CreateRecipePage extends ConsumerStatefulWidget {
  const CreateRecipePage({super.key});

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  var _category = '家常菜';
  var _saving = false;
  String? _titleError;
  String? _categoryError;
  String? _templateError;

  static const _categories = ['家常菜', '主食', '汤羹', '烘焙', '甜品', '小吃', '饮品', '其他'];

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

  Future<void> _save() async {
    final input = _createInput;
    // 页面先校验一次以立即标记字段；UseCase 内仍会再次校验，防止其他入口绕过规则。
    final validationFailure = const CreateRecipeValidationService()(input);
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
      final id = await ref
          .read(recipeEditorDependenciesProvider)
          .createRecipe(input);
      // await 期间用户可能已经退出页面；mounted 防止继续使用已销毁的 context。
      if (mounted) context.replaceWithRecipeDetail(id);
    } on CreateRecipeValidationFailure catch (failure) {
      if (mounted) _applyValidationFailure(failure);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试')));
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
    _showValidationMessage(failure.firstError);
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建菜谱'),
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
                  onChanged: (_) => setState(() => _titleError = null),
                  decoration: InputDecoration(
                    labelText: '菜名 *',
                    hintText: '例如：番茄炒蛋',
                    errorText: _titleError,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                TextFormField(
                  controller: _summaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '简介',
                    hintText: '这道菜有什么特别之处？',
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: '主分类',
                    errorText: _categoryError,
                  ),
                  items: _categories
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
              onChanged: (_) => setState(() {}),
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
                  SizedBox(
                    width: 220,
                    child: RecipeTemplateRendererWidget(
                      definition: BuiltInTemplates.basicJournal,
                      data: _templateRenderData,
                      mode: TemplateRenderMode.reader,
                    ),
                  ),
                  if (_templateError != null) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      _templateError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
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
              onChanged: (_) => setState(() {}),
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
            label: Text(_saving ? '正在保存…' : '保存菜谱'),
          ),
        ],
      ),
    );
  }

  CreateRecipeInput get _createInput {
    return CreateRecipeInput(
      title: _titleController.text,
      summary: _summaryController.text,
      category: _category,
      ingredients: _linesOf(_ingredientsController),
      steps: _linesOf(_stepsController),
      templateSelection: BuiltInTemplates.defaultSelection,
    );
  }

  TemplateRenderData get _templateRenderData {
    const parser = IngredientLineParserService();
    // 预览与最终保存共用同一个领域解析器，避免用户看到的结果和落库结果不一致。
    final ingredients = _linesOf(_ingredientsController)
        .take(4)
        .map(parser.call)
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
      category: _category,
      totalMinutes: null,
      isIncomplete: ingredients.isEmpty || _linesOf(_stepsController).isEmpty,
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
