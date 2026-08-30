import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_size.dart';
import '../foundation/kitchen_design_app_spacing.dart';
import '../foundation/kitchen_design_app_text.dart';

/// 一级页面使用的可收缩顶部栏。
///
/// 展开时保留大标题和副标题，向上滚动后将标题收缩到固定的顶部栏；
/// 后续的 pinned sliver 会自动从该顶部栏下方开始吸顶。
class AppSliverPageHeader extends StatelessWidget {
  const AppSliverPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.expandedDecoration,
    this.subtitleColor = AppColor.x7E756E,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? expandedDecoration;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      key: key,
      pinned: true,
      delegate: _AppSliverPageHeaderDelegate(
        title: title,
        subtitle: subtitle,
        action: action,
        expandedDecoration: expandedDecoration,
        subtitleColor: subtitleColor,
      ),
    );
  }
}

class _AppSliverPageHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _AppSliverPageHeaderDelegate({
    required this.title,
    required this.subtitle,
    this.action,
    this.expandedDecoration,
    required this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? expandedDecoration;
  final Color subtitleColor;

  @override
  double get minExtent => AppSize.pageHeaderCollapsedHeight;

  @override
  double get maxExtent => AppSize.pageHeaderExpandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseRange = maxExtent - minExtent;
    final progress = (shrinkOffset / collapseRange).clamp(0.0, 1.0);
    final navigationOpacity = progress;
    final titleTop = lerpDouble(AppSpacing.s12, 19, progress)!;
    final subtitleTop = titleTop + AppText.libraryTitle + AppSpacing.s8;
    final theme = Theme.of(context);
    final titleStyle = TextStyle.lerp(
      theme.textTheme.displaySmall?.copyWith(
        color: AppColor.x60483A,
        fontSize: AppText.libraryTitle,
        fontWeight: FontWeight.w800,
        height: 1,
        inherit: true,
      ),
      theme.appBarTheme.titleTextStyle?.copyWith(
            color: AppColor.x60483A,
            fontSize: AppText.title,
            fontWeight: FontWeight.w700,
            height: 1.2,
            inherit: true,
          ) ??
          const TextStyle(
            color: AppColor.x60483A,
            fontSize: AppText.title,
            fontWeight: FontWeight.w700,
            height: 1.2,
            inherit: true,
          ),
      progress,
    );

    return Material(
      key: const Key('app-sliver-page-header-surface'),
      color: Colors.transparent,
      elevation: overlapsContent ? 2 : 0,
      shadowColor: AppColor.x60483A.withValues(alpha: 0.14),
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: minExtent,
              child: Opacity(
                key: const Key('app-sliver-page-header-navigation'),
                opacity: navigationOpacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: const Border(
                      bottom: BorderSide(color: AppColor.xE8DAC1, width: 1),
                    ),
                  ),
                ),
              ),
            ),
            if (expandedDecoration != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    key: const Key('app-sliver-page-header-decoration'),
                    opacity: 1 - progress,
                    child: expandedDecoration,
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.s24,
              right: action == null ? AppSpacing.s24 : AppSpacing.s56,
              top: titleTop,
              child: Text(
                title,
                key: const Key('app-sliver-page-header-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            Positioned(
              left: AppSpacing.s24,
              right: AppSpacing.s24,
              top: subtitleTop,
              child: Opacity(
                key: const Key('app-sliver-page-header-subtitle'),
                opacity: 1 - progress,
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subtitleColor,
                    fontSize: AppText.librarySubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (action != null)
              Positioned(
                right: AppSpacing.s4,
                top: AppSpacing.s4,
                child: action!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AppSliverPageHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        action != oldDelegate.action ||
        expandedDecoration != oldDelegate.expandedDecoration ||
        subtitleColor != oldDelegate.subtitleColor;
  }
}
