import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_notes/src/data/app_database.dart';
import 'package:kitchen_notes/src/data/recipe_repository.dart';
import 'package:kitchen_notes/src/theme/app_theme.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(recipeDetailProvider(recipeId));
    return detail.when(
      data: (data) => data == null
          ? const Scaffold(body: Center(child: Text('菜谱不存在或已被删除')))
          : _RecipeDetailContent(detail: data),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('菜谱加载失败：$error'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _RecipeDetailContent extends ConsumerWidget {
  const _RecipeDetailContent({required this.detail});

  final RecipeDetailData detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = detail.recipe;
    final totalMinutes = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 250,
            pinned: true,
            title: Text(recipe.title),
            actions: [
              IconButton(
                tooltip: recipe.isFavorite ? '取消收藏' : '收藏',
                onPressed: () async {
                  await ref
                      .read(recipeRepositoryProvider)
                      .toggleFavorite(recipe);
                  ref.invalidate(recipeDetailProvider(recipe.id));
                },
                icon: Icon(
                  recipe.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: recipe.isFavorite ? AppColors.coral : null,
                ),
              ),
              IconButton(
                tooltip: '更多',
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Color(recipe.coverColor),
                child: const Center(
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: 72,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList.list(
              children: [
                if (recipe.summary.isNotEmpty) ...[
                  Text(
                    recipe.summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: AppColors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (recipe.servings != null)
                      _InfoChip(
                        icon: Icons.people_outline_rounded,
                        label: '${recipe.servings} 人份',
                      ),
                    if (totalMinutes > 0)
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: '$totalMinutes 分钟',
                      ),
                    _InfoChip(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: recipe.difficulty,
                    ),
                    _InfoChip(
                      icon: Icons.sell_outlined,
                      label: recipe.category,
                    ),
                  ],
                ),
                if (detail.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: detail.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 28),
                _SectionTitle(
                  title: '食材',
                  trailing: '${detail.ingredients.length} 种',
                ),
                const SizedBox(height: 12),
                if (detail.ingredients.isEmpty)
                  const _MissingContent(message: '还没有添加食材')
                else
                  ..._ingredientSections(),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: '烹饪步骤',
                  trailing: '${detail.steps.length} 步',
                ),
                const SizedBox(height: 12),
                if (detail.steps.isEmpty)
                  const _MissingContent(message: '还没有添加烹饪步骤')
                else
                  ...detail.steps.indexed.map(
                    (item) => _StepTile(number: item.$1 + 1, step: item.$2),
                  ),
                const SizedBox(height: 28),
                const _SectionTitle(title: '我的笔记'),
                const SizedBox(height: 12),
                const _MissingContent(message: '记录自己的口味和调整'),
                const SizedBox(height: 28),
                const _SectionTitle(title: '来源'),
                const SizedBox(height: 12),
                const Text('手动创建', style: TextStyle(color: AppColors.mutedInk)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: detail.steps.isEmpty
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('逐步烹饪模式将在下一迭代接入')),
                  );
                },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('开始烹饪'),
        ),
      ),
    );
  }

  List<Widget> _ingredientSections() {
    final widgets = <Widget>[];
    if (detail.groups.isEmpty) {
      return detail.ingredients
          .map((ingredient) => _IngredientTile(ingredient: ingredient))
          .toList();
    }
    for (final group in detail.groups) {
      final items = detail.ingredients
          .where((ingredient) => ingredient.groupId == group.id)
          .toList();
      if (items.isEmpty) continue;
      if (detail.groups.length > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              group.name,
              style: const TextStyle(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      widgets.addAll(
        items.map((ingredient) => _IngredientTile(ingredient: ingredient)),
      );
    }
    return widgets;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.butter),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.coral),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: const TextStyle(color: AppColors.mutedInk)),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.sage,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient.preparation == null
                  ? ingredient.name
                  : '${ingredient.name} · ${ingredient.preparation}',
            ),
          ),
          Text(
            ingredient.amountText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.title != null) ...[
                  Text(
                    step.title!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(step.instruction, style: const TextStyle(height: 1.55)),
                if (step.durationMinutes != null || step.heatLevel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (step.heatLevel != null) step.heatLevel!,
                      if (step.durationMinutes != null)
                        '约 ${step.durationMinutes} 分钟',
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingContent extends StatelessWidget {
  const _MissingContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.butter),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.mutedInk)),
    );
  }
}
