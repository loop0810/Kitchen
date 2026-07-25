import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_notes/src/data/recipe_repository.dart';
import 'package:kitchen_notes/src/features/recipes/widgets/recipe_card.dart';

class RecipeLibraryScreen extends ConsumerStatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  ConsumerState<RecipeLibraryScreen> createState() =>
      _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends ConsumerState<RecipeLibraryScreen> {
  final _searchController = TextEditingController();
  var _query = '';
  var _filter = 'all';

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
            onPressed: () => context.push('/recipes/new'),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: '全部',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                _FilterChip(
                  label: '收藏',
                  selected: _filter == 'favorite',
                  onTap: () => setState(() => _filter = 'favorite'),
                ),
                _FilterChip(
                  label: '做过',
                  selected: _filter == 'cooked',
                  onTap: () => setState(() => _filter = 'cooked'),
                ),
                _FilterChip(
                  label: '待完善',
                  selected: _filter == 'incomplete',
                  onTap: () => setState(() => _filter = 'incomplete'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recipes.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyLibrary(
                    hasFilter: _query.isNotEmpty || _filter != 'all',
                    onCreate: () => context.push('/recipes/new'),
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
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () => context.push('/recipes/${recipe.id}'),
                      onFavorite: () => ref
                          .read(recipeRepositoryProvider)
                          .toggleFavorite(recipe),
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
      padding: const EdgeInsets.only(right: 8),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.menu_book_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? '没有找到符合条件的菜谱' : '开始建立你的菜谱本',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 16),
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
