import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_notes/src/data/recipe_repository.dart';
import 'package:kitchen_notes/src/features/recipes/widgets/recipe_card_widget.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                        const Icon(Icons.search_off_rounded, size: 52),
                        const SizedBox(height: 12),
                        const Text('没有找到相关菜谱'),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/recipes/new'),
                          icon: const Icon(Icons.add_rounded),
                          label: Text('创建“$_query”'),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final recipe = items[index];
                    return RecipeCardWidget(
                      recipe: recipe,
                      onTap: () => context.push('/recipes/${recipe.id}'),
                      onFavorite: () => ref
                          .read(recipeRepositoryProvider)
                          .toggleFavorite(recipe),
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
