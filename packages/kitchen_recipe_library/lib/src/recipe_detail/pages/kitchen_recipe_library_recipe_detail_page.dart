import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../../recipe_library/providers/kitchen_recipe_library_dependencies.dart';

class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

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

  final RecipeDetailEntity detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = detail.recipe;
    final totalMinutes = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: AppSize.recipeHeaderHeight,
            pinned: true,
            title: Text(recipe.title),
            actions: [
              IconButton(
                tooltip: recipe.isFavorite ? '取消收藏' : '收藏',
                onPressed: () async {
                  await ref
                      .read(recipeLibraryDependenciesProvider)
                      .setFavorite(
                        recipeId: recipe.id,
                        isFavorite: !recipe.isFavorite,
                      );
                  // 详情使用一次性 Future；写入完成后主动失效缓存以读取最新收藏状态。
                  // 菜谱列表使用数据库 Stream，会由 Drift 自动推送更新，无需手动刷新。
                  ref.invalidate(recipeDetailProvider(recipe.id));
                },
                icon: Icon(
                  recipe.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: recipe.isFavorite ? AppColor.coral : null,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Color(recipe.coverColor),
                child: const Center(
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: AppSize.icon72,
                    color: AppColor.white70,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s20,
              AppSpacing.s16,
              AppSpacing.s120,
            ),
            sliver: SliverList.list(
              children: [
                if (recipe.summary.isNotEmpty) ...[
                  Text(
                    recipe.summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: AppText.bodyLineHeight,
                      color: AppColor.mutedInk,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s18),
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
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: 8,
                    children: detail.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.s28),
                _SectionTitle(
                  title: '食材',
                  trailing: '${detail.ingredients.length} 种',
                ),
                const SizedBox(height: AppSpacing.s12),
                if (detail.ingredients.isEmpty)
                  const _MissingContent(message: '还没有添加食材')
                else
                  ..._ingredientSections(),
                const SizedBox(height: AppSpacing.s28),
                _SectionTitle(
                  title: '烹饪步骤',
                  trailing: '${detail.steps.length} 步',
                ),
                const SizedBox(height: AppSpacing.s12),
                if (detail.steps.isEmpty)
                  const _MissingContent(message: '还没有添加烹饪步骤')
                else
                  ...detail.steps.indexed.map(
                    (item) => _StepTile(number: item.$1 + 1, step: item.$2),
                  ),
                const SizedBox(height: AppSpacing.s28),
                const _SectionTitle(title: '我的笔记'),
                const SizedBox(height: AppSpacing.s12),
                const _MissingContent(message: '记录自己的口味和调整'),
                const SizedBox(height: AppSpacing.s28),
                const _SectionTitle(title: '来源'),
                const SizedBox(height: AppSpacing.s12),
                const Text('手动创建', style: TextStyle(color: AppColor.mutedInk)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s12,
        ),
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
    // 食材只有一套用户维护的全局顺序，详情不再插入任何隐式分组标题。
    return detail.ingredients
        .map((ingredient) => _IngredientTile(ingredient: ingredient))
        .toList(growable: false);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColor.butter),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.icon17, color: AppColor.coral),
          const SizedBox(width: AppSpacing.s6),
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
          Text(trailing!, style: const TextStyle(color: AppColor.mutedInk)),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient});

  final IngredientEntity ingredient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s9),
      child: Row(
        children: [
          Container(
            width: AppSize.icon8,
            height: AppSize.icon8,
            decoration: const BoxDecoration(
              color: AppColor.sage,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
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
  final RecipeStepEntity step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSize.icon32,
            height: AppSize.icon32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColor.blush,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColor.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step.title != null) ...[
                  Text(
                    step.title!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                ],
                Text(
                  step.instruction,
                  style: const TextStyle(height: AppText.instructionLineHeight),
                ),
                if (step.durationMinutes != null || step.heatLevel != null) ...[
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    [
                      if (step.heatLevel != null) step.heatLevel!,
                      if (step.durationMinutes != null)
                        '约 ${step.durationMinutes} 分钟',
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColor.mutedInk,
                      fontSize: AppText.detail,
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
      padding: const EdgeInsets.all(AppSpacing.s18),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColor.butter),
      ),
      child: Text(message, style: const TextStyle(color: AppColor.mutedInk)),
    );
  }
}
