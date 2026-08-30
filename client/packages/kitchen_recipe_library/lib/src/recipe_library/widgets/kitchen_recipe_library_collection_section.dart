import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_collection_book_card.dart';

class RecipeLibraryCollectionSection extends StatelessWidget {
  const RecipeLibraryCollectionSection({
    super.key,
    required this.collections,
    required this.onTap,
    required this.onLongPress,
  });

  final AsyncValue<List<RecipeCollectionEntity>> collections;
  final ValueChanged<RecipeCollectionEntity> onTap;
  final void Function(RecipeCollectionEntity, Offset) onLongPress;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('recipe-collection-scroll'),
      slivers: [
        collections.when(
          data: (items) => items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: const _EmptyCollections(),
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
                          final collection = items[index];
                          return RecipeLibraryCollectionBookCard(
                            key: ValueKey(collection.id),
                            collection: collection,
                            onTap: () => onTap(collection),
                            onLongPress: (position) =>
                                onLongPress(collection, position),
                          );
                        }, childCount: items.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.s16,
                          mainAxisSpacing: AppSpacing.s20,
                          childAspectRatio: columns == 1 ? 0.9 : 0.7,
                        ),
                      ),
                    );
                  },
                ),
          error: (_, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('菜谱集加载失败，请稍后重试')),
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

class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.collections_bookmark_outlined, size: AppSize.icon54),
        const SizedBox(height: AppSpacing.s16),
        const Text('把常做的菜整理进菜谱集'),
      ],
    ),
  );
}
