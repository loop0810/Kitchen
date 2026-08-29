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
    this.placeholder = false,
    this.onLongPress,
  });

  final RecipeJournalSummaryEntity recipe;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool placeholder;
  final ValueChanged<Offset>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final entity = recipe.recipe;
    return Builder(
      builder: (cardContext) => Semantics(
        button: true,
        label: placeholder ? _semanticLabel : null,
        onLongPress: onLongPress == null
            ? null
            : () {
                final box = cardContext.findRenderObject()! as RenderBox;
                onLongPress!(box.localToGlobal(box.size.center(Offset.zero)));
              },
        child: GestureDetector(
          onLongPressStart: onLongPress == null
              ? null
              : (details) => onLongPress!(details.globalPosition),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: placeholder
                ? _PlaceholderCardBody(
                    color: _placeholderColor(entity.coverColor),
                    isFavorite: entity.isFavorite,
                    onTap: onTap,
                    onFavorite: onFavorite,
                  )
                : _RenderedCardBody(
                    recipe: recipe,
                    onTap: onTap,
                    onFavorite: onFavorite,
                  ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    final ingredients = recipe.primaryIngredients.isEmpty
        ? '食材待补充'
        : recipe.primaryIngredients
              .map(
                (ingredient) => '${ingredient.name} ${ingredient.amountText}',
              )
              .join('，');
    final entity = recipe.recipe;
    final status = entity.status == RecipeStatus.incomplete ? '，待完善' : '';
    return '${entity.title}。主要食材：$ingredients$status';
  }
}

class _PlaceholderCardBody extends StatelessWidget {
  const _PlaceholderCardBody({
    required this.color,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  final Color color;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: AppSpacing.s4,
              top: AppSpacing.s4,
              child: IconButton(
                tooltip: isFavorite ? '取消收藏' : '收藏',
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColor.xF26A58 : AppColor.x7E756E,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColor.xFFFAF2.withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenderedCardBody extends StatelessWidget {
  const _RenderedCardBody({
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
    return InkWell(
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
                  color: AppColor.xFFFAF2.withValues(alpha: 0.94),
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
                color: entity.isFavorite ? AppColor.xF26A58 : AppColor.x7E756E,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColor.xFFFAF2.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _placeholderColor(int value) {
  return (value & 0xFF000000) == 0 ? AppColor.xF5DDD5 : Color(value);
}
