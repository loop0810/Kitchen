import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_dependencies.dart';
import 'kitchen_recipe_library_recipe_card_widget.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(recipesProvider(RecipeQuery(text: _query)));
    return Scaffold(
      appBar: AppBar(title: const Text('搜索菜谱')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s4,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery.isEmpty,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '搜索菜名、食材或标签',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: results.when(
              data: (items) {
                if (_query.trim().isEmpty) {
                  return const _SearchPrompt();
                }
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: AppSize.icon52,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        const Text('没有找到相关菜谱'),
                        const SizedBox(height: AppSpacing.s16),
                        OutlinedButton.icon(
                          onPressed: context.pushCreateRecipe,
                          icon: const Icon(Icons.add_rounded),
                          label: Text('创建“$_query”'),
                        ),
                      ],
                    ),
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
                    final summary = items[index];
                    final recipe = summary.recipe;
                    return RecipeCardWidget(
                      recipe: summary,
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
              error: (error, stackTrace) => Center(child: Text('搜索失败：$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '可以搜索菜名、食材或标签',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
