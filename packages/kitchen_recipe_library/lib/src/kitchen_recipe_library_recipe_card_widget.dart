import 'package:flutter/material.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

class RecipeCardWidget extends StatelessWidget {
  const RecipeCardWidget({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavorite,
  });

  final RecipeJournalSummaryEntity recipe;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final entity = recipe.recipe;
    final resolution = BuiltInTemplates.defaultResolver(
      entity.templateSelection,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: RecipeTemplateRendererWidget(
                definition: resolution.definition,
                data: RecipeTemplateDataMapper.fromJournalSummary(recipe),
                mode: TemplateRenderMode.thumbnail,
              ),
            ),
            if (entity.status == RecipeStatus.incomplete)
              Positioned(
                left: AppSpacing.s8,
                bottom: AppSpacing.s8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.paper.withValues(alpha: 0.94),
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
              right: AppSpacing.s4,
              top: AppSpacing.s4,
              child: IconButton(
                tooltip: entity.isFavorite ? '取消收藏' : '收藏',
                onPressed: onFavorite,
                icon: Icon(
                  entity.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: entity.isFavorite ? AppColor.coral : AppColor.mutedInk,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColor.paper.withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
