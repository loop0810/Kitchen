import 'package:flutter/material.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class RecipeLibraryCollectionBookCard extends StatelessWidget {
  const RecipeLibraryCollectionBookCard({
    super.key,
    required this.collection,
    required this.onTap,
    required this.onLongPress,
  });

  final RecipeCollectionEntity collection;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = _bookColors(collection.id);
    return Semantics(
      button: true,
      label: collection.memberCount == 0
          ? '${collection.name}，空菜谱集，点击添加菜谱，长按管理'
          : '${collection.name}，${collection.memberCount} 道菜谱，点击翻阅，长按管理',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: (details) => onLongPress(details.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 10,
                        offset: Offset(4, 6),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        left: AppSpacing.s8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColor.xFFFAF2,
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                            border: Border.all(color: colors.$2, width: 2),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        right: AppSpacing.s6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                          child: collection.coverBytes == null
                              ? _DefaultBookCover(
                                  name: collection.name,
                                  colors: colors,
                                )
                              : Image.memory(
                                  collection.coverBytes!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 450,
                                  errorBuilder: (_, _, _) => _DefaultBookCover(
                                    name: collection.name,
                                    colors: colors,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: AppSpacing.s12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.$2,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(AppRadius.r12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              collection.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              '${collection.memberCount} 道菜谱',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBookCover extends StatelessWidget {
  const _DefaultBookCover({required this.name, required this.colors});

  final String name;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: colors.$1,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: AppSpacing.s16,
          right: AppSpacing.s12,
          child: Icon(Icons.local_florist_outlined, color: colors.$2),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.$2),
              borderRadius: BorderRadius.circular(AppRadius.r18),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.$2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: AppSpacing.s16,
          child: Icon(Icons.restaurant_menu_rounded, color: colors.$2),
        ),
      ],
    ),
  );
}

(Color, Color) _bookColors(String id) {
  const palettes = [
    (Color(0xFFF3D9D2), Color(0xFF8D4D43)),
    (Color(0xFFDDE7D6), Color(0xFF4F6948)),
    (Color(0xFFE6DDF0), Color(0xFF66507A)),
    (Color(0xFFF0E2BE), Color(0xFF786137)),
  ];
  return palettes[id.hashCode.abs() % palettes.length];
}
