import 'package:flutter/material.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeCardWidget extends StatelessWidget {
  const RecipeCardWidget({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavorite,
  });

  final RecipeEntity recipe;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Color(recipe.coverColor),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: AppSize.icon44,
                        color: AppColor.white70,
                      ),
                    ),
                    if (recipe.status == RecipeStatus.incomplete)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.paper.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppRadius.r10),
                          ),
                          child: const Text(
                            '待完善',
                            style: TextStyle(
                              fontSize: AppText.caption,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton(
                        tooltip: recipe.isFavorite ? '取消收藏' : '收藏',
                        onPressed: onFavorite,
                        icon: Icon(
                          recipe.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: recipe.isFavorite
                              ? AppColor.coral
                              : AppColor.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s11,
                AppSpacing.s12,
                AppSpacing.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppText.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: AppSize.icon14,
                        color: AppColor.mutedInk,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        totalMinutes > 0 ? '$totalMinutes 分钟' : '时间待补充',
                        style: const TextStyle(
                          color: AppColor.mutedInk,
                          fontSize: AppText.label,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
