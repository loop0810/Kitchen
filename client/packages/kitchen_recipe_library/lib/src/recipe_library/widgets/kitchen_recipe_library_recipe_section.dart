import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_recipe_card_widget.dart';

class RecipeLibraryRecipeSection extends StatelessWidget {
  const RecipeLibraryRecipeSection({
    super.key,
    required this.recipes,
    required this.hasFilter,
    required this.onCreate,
    required this.onTap,
    required this.onFavorite,
    required this.onLongPress,
  });

  final AsyncValue<List<RecipeJournalSummaryEntity>> recipes;
  final bool hasFilter;
  final VoidCallback onCreate;
  final ValueChanged<RecipeJournalSummaryEntity> onTap;
  final ValueChanged<RecipeJournalSummaryEntity> onFavorite;
  final void Function(RecipeJournalSummaryEntity, Offset) onLongPress;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('recipe-library-scroll'),
      slivers: [
        recipes.when(
          data: (items) => items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyLibrary(
                    hasFilter: hasFilter,
                    onCreate: onCreate,
                  ),
                )
              : SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final columns =
                        constraints.crossAxisExtent < 320 || textScale > 1.3
                        ? 1
                        : 2;
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s16,
                        AppSpacing.s10,
                        AppSpacing.s16,
                        AppSpacing.s24,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final summary = items[index];
                          return RecipeCardWidget(
                            recipe: summary,
                            placeholder: true,
                            onTap: () => onTap(summary),
                            onFavorite: () => onFavorite(summary),
                            onLongPress: (position) =>
                                onLongPress(summary, position),
                          );
                        }, childCount: items.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.s12,
                          mainAxisSpacing: AppSpacing.s12,
                          childAspectRatio: AppSize.recipeCardAspectRatio,
                        ),
                      ),
                    );
                  },
                ),
          error: (_, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('菜谱加载失败，请稍后重试')),
          ),
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.hasFilter, required this.onCreate});

  final bool hasFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasFilter ? Icons.search_off_rounded : Icons.menu_book_rounded,
          size: AppSize.icon54,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(hasFilter ? '没有找到符合条件的菜谱' : '开始建立你的菜谱本'),
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
  );
}
