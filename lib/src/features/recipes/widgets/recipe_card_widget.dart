import 'package:flutter/material.dart';
import 'package:kitchen_notes/src/data/app_database.dart';
import 'package:kitchen_notes/src/theme/app_theme.dart';

class RecipeCardWidget extends StatelessWidget {
  const RecipeCardWidget({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavorite,
  });

  final Recipe recipe;
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
                        size: 44,
                        color: Colors.white70,
                      ),
                    ),
                    if (recipe.status == 'incomplete')
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '待完善',
                            style: TextStyle(
                              fontSize: 11,
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
                              ? AppColors.coral
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.mutedInk,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        totalMinutes > 0 ? '$totalMinutes 分钟' : '时间待补充',
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 12,
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
