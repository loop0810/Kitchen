import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_editor_dependencies.dart';

class CreateRecipePage extends ConsumerStatefulWidget {
  const CreateRecipePage({super.key});

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  var _category = '家常菜';
  var _saving = false;

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(recipeEditorDependenciesProvider)
          .createRecipe(
            CreateRecipeInput(
              title: _titleController.text,
              summary: _summaryController.text,
              category: _category,
              ingredients: _linesOf(_ingredientsController),
              steps: _linesOf(_stepsController),
            ),
          );
      if (mounted) context.goToRecipeDetail(id);
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
      body: Form(
        key: _formKey,
        child: ListView(
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
                    decoration: const InputDecoration(
                      labelText: '菜名',
                      hintText: '例如：番茄炒蛋',
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '请输入菜名' : null,
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
                    decoration: const InputDecoration(labelText: '主分类'),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
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
              title: '步骤',
              subtitle: '每行一个步骤，保存后可以继续完善',
              child: TextFormField(
                controller: _stepsController,
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
      ),
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
