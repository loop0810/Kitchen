import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/kitchen_recipe_editor_dependencies.dart';
import '../widgets/kitchen_recipe_editor_recipe_form_widget.dart';

class EditRecipePage extends ConsumerWidget {
  const EditRecipePage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(recipeEditorDetailProvider(recipeId));
    return detail.when(
      data: (value) => value == null
          ? const Scaffold(body: Center(child: Text('菜谱不存在或已被删除')))
          : RecipeEditorFormWidget(initialDetail: value),
      error: (error, stackTrace) =>
          const Scaffold(body: Center(child: Text('菜谱加载失败，请稍后重试'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
