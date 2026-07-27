import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_dependencies.dart';
import 'kitchen_recipe_library_recipe_card_widget.dart';

class RecipeLibraryPage extends ConsumerStatefulWidget {
  const RecipeLibraryPage({super.key});

  @override
  ConsumerState<RecipeLibraryPage> createState() => _RecipeLibraryPageState();
}

class _RecipeLibraryPageState extends ConsumerState<RecipeLibraryPage> {
  final _searchController = TextEditingController();
  var _query = '';
  var _filter = RecipeStatusFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(
      recipesProvider(RecipeQuery(text: _query, statusFilter: _filter)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的菜谱'),
        actions: [
          IconButton(
            tooltip: '创建菜谱',
            onPressed: context.pushCreateRecipe,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s4,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: '搜索我的菜谱',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: AppSize.filterBarHeight,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: '全部',
                  selected: _filter == RecipeStatusFilter.all,
                  onTap: () => setState(() => _filter = RecipeStatusFilter.all),
                ),
                _FilterChip(
                  label: '收藏',
                  selected: _filter == RecipeStatusFilter.favorite,
                  onTap: () =>
                      setState(() => _filter = RecipeStatusFilter.favorite),
                ),
                _FilterChip(
                  label: '做过',
                  selected: _filter == RecipeStatusFilter.cooked,
                  onTap: () =>
                      setState(() => _filter = RecipeStatusFilter.cooked),
                ),
                _FilterChip(
                  label: '待完善',
                  selected: _filter == RecipeStatusFilter.incomplete,
                  onTap: () =>
                      setState(() => _filter = RecipeStatusFilter.incomplete),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Expanded(
            child: recipes.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyLibrary(
                    hasFilter:
                        _query.isNotEmpty || _filter != RecipeStatusFilter.all,
                    onCreate: context.pushCreateRecipe,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s16,
                    AppSpacing.s24,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: AppSize.recipeCardAspectRatio,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final recipe = items[index];
                    return RecipeCardWidget(
                      recipe: recipe,
                      onTap: () => context.pushRecipeDetail(recipe.id),
                      onFavorite: () => ref
                          .read(recipeLibraryDependenciesProvider)
                          .setFavorite(
                            recipeId: recipe.id,
                            isFavorite: !recipe.isFavorite,
                          ),
                    );
                  },
                );
              },
              error: (error, stackTrace) => Center(
                child: Text('菜谱加载失败\n$error', textAlign: TextAlign.center),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.hasFilter, required this.onCreate});

  final bool hasFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.menu_book_rounded,
              size: AppSize.icon54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              hasFilter ? '没有找到符合条件的菜谱' : '开始建立你的菜谱本',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: AppSpacing.s16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('创建第一道菜谱'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
