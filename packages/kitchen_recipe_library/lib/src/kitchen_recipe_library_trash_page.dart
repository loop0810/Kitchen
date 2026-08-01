import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_dependencies.dart';

class RecipeTrashPage extends ConsumerStatefulWidget {
  const RecipeTrashPage({super.key});

  @override
  ConsumerState<RecipeTrashPage> createState() => _RecipeTrashPageState();
}

class _RecipeTrashPageState extends ConsumerState<RecipeTrashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(recipeLibraryDependenciesProvider)
          .purgeExpiredRecipes
          ?.call();
      ref.invalidate(recipesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(
      recipesProvider(
        const RecipeQuery(
          scope: RecipeListScope.trash,
          sortOrder: RecipeSortOrder.recentlyUpdated,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: recipes.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('回收站是空的'))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final recipe = items[index].recipe;
                  return Card(
                    child: ListTile(
                      title: Text(recipe.title),
                      subtitle: Text(
                        '剩余 ${_remainingDays(recipe.deletedAt)} 天后自动清理',
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: '管理已删除菜谱',
                        onSelected: (action) => action == 'restore'
                            ? _restore(recipe.id)
                            : _permanentlyDelete(recipe),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'restore', child: Text('恢复')),
                          PopupMenuItem(value: 'delete', child: Text('永久删除')),
                        ],
                      ),
                    ),
                  );
                },
              ),
        error: (_, _) => const Center(child: Text('回收站加载失败，请稍后重试')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  int _remainingDays(DateTime? deletedAt) {
    if (deletedAt == null) return 0;
    final remaining = deletedAt
        .add(const Duration(days: 30))
        .difference(DateTime.now());
    return remaining.isNegative ? 0 : (remaining.inHours / 24).ceil();
  }

  Future<void> _restore(String id) async {
    await ref.read(recipeLibraryDependenciesProvider).restoreRecipe?.call(id);
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('菜谱已恢复')));
    }
  }

  Future<void> _permanentlyDelete(RecipeEntity recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除菜谱？'),
        content: Text('“${recipe.title}”将被永久删除，此操作无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(recipeLibraryDependenciesProvider)
        .permanentlyDeleteRecipe
        ?.call(recipe.id);
    ref.invalidate(recipesProvider);
  }
}
