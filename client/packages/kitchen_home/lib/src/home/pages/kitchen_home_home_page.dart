import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    context.pushSearch(query);
  }

  void _showRecipeCreationOptions() {
    showAppActionSheet(
      context: context,
      title: '创建菜谱',
      subtitle: '选择一种开始方式',
      actions: [
        AppActionSheetAction(
          iconAsset: 'assets/images/recipe_creation_manual.png',
          iconAssetPackage: 'kitchen_home',
          title: '手动创建',
          onTap: () => context.pushCreateRecipe<void>(),
        ),
        AppActionSheetAction(
          iconAsset: 'assets/images/recipe_creation_link.png',
          iconAssetPackage: 'kitchen_home',
          title: '粘贴文章或链接',
          onTap: () => context.pushPasteImport<void>(),
        ),
        AppActionSheetAction(
          iconAsset: 'assets/images/recipe_creation_image.png',
          iconAssetPackage: 'kitchen_home',
          title: '选择图片',
          onTap: () => context.pushImageImport<void>(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.min(
            337.0,
            math.max(0.0, constraints.maxWidth - AppSpacing.s56),
          );
          final illustrationHeight = math.min(
            220.0,
            math.max(140.0, constraints.maxHeight * 0.28),
          );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: contentWidth,
                    height: illustrationHeight,
                    child: Image.asset(
                      'assets/images/home_kitchen_illustration.png',
                      package: 'kitchen_home',
                      fit: BoxFit.contain,
                      semanticLabel: '厨房食材插图',
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    '今天想吃点什么',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Container(
                    width: AppSpacing.s56,
                    height: AppSpacing.s4,
                    decoration: BoxDecoration(
                      color: AppColor.xF5D477,
                      borderRadius: BorderRadius.circular(AppRadius.r10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  _HomeShadowSurface(
                    key: const Key('home-search-surface'),
                    child: SizedBox(
                      height: AppSize.homeControlHeight,
                      child: TextField(
                        key: const Key('home-search-field'),
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: const TextStyle(
                          color: AppColor.x60483A,
                          fontSize: AppText.body,
                        ),
                        decoration: InputDecoration(
                          hintText: '搜索菜名、食材或标签',
                          hintStyle: const TextStyle(
                            color: AppColor.x7E756E,
                            fontSize: AppText.body,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColor.x60483A,
                            size: AppSize.icon30,
                          ),
                          filled: true,
                          fillColor: AppColor.xFFFDF6,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.r22),
                            borderSide: const BorderSide(
                              color: AppColor.x60483A,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.r22),
                            borderSide: const BorderSide(
                              color: AppColor.x60483A,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.r22),
                            borderSide: const BorderSide(
                              color: AppColor.xF26A58,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  _HomeShadowSurface(
                    key: const Key('home-create-surface'),
                    shadowColor: AppColor.xA94B3F,
                    child: SizedBox(
                      height: AppSize.homeControlHeight,
                      width: double.infinity,
                      child: _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: '创建菜谱',
                        onTap: _showRecipeCreationOptions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeShadowSurface extends StatelessWidget {
  const _HomeShadowSurface({
    super.key,
    required this.child,
    this.shadowColor = AppColor.xEADCC3,
  });

  final Widget child;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r22),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: AppSize.icon20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSize.homeControlHeight),
        foregroundColor: AppColor.xFFFFFF,
        side: const BorderSide(color: AppColor.xA94B3F, width: 2),
        backgroundColor: AppColor.xF26A58,
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(
          fontSize: AppText.body,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r22),
        ),
      ),
    );
  }
}
