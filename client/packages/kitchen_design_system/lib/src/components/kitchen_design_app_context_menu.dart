import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_spacing.dart';

/// 长按锚点菜单中的一个可选操作。
class AppContextMenuAction {
  const AppContextMenuAction({
    required this.title,
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.iconAssetPackage,
    this.foregroundColor,
  }) : assert(
         icon == null || iconAsset == null,
         'icon and iconAsset cannot both be provided',
       ),
       assert(
         iconAssetPackage == null || iconAsset != null,
         'iconAssetPackage requires iconAsset',
       );

  /// 操作标题。
  final String title;

  /// 操作的 Material 图标；所有操作都不提供图标时，菜单会自动使用无图标布局。
  final IconData? icon;

  /// 操作的资源图片；适合使用功能 package 提供的设计稿图标。
  final String? iconAsset;

  /// 资源图片所属的 package；为空时从当前应用资源中加载。
  final String? iconAssetPackage;

  /// 点击操作后执行的回调。
  final FutureOr<void> Function() onTap;

  /// 标题和图标颜色；未提供时使用设计系统默认墨棕色。
  final Color? foregroundColor;
}

/// 在指定的全局坐标处展示长按锚点菜单。
Future<void> showAppContextMenu({
  required BuildContext context,
  required Offset anchorPosition,
  required List<AppContextMenuAction> actions,
}) async {
  if (actions.isEmpty) return;

  final selectedIndex = await showGeneralDialog<int>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: true,
    barrierLabel: '关闭操作菜单',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, animation, secondaryAnimation) {
      final screenSize = MediaQuery.sizeOf(context);
      final menuWidth = math.min(
        _AppContextMenuMetrics.menuWidth,
        math.max(1.0, screenSize.width - AppSpacing.s24),
      );
      return CustomSingleChildLayout(
        delegate: _AppContextMenuLayoutDelegate(
          anchorPosition: anchorPosition,
          menuWidth: menuWidth,
        ),
        child: AppContextMenu(
          width: menuWidth,
          actions: actions,
          onSelected: (index) => Navigator.of(context).pop(index),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(opacity: curvedAnimation, child: child);
    },
  );

  if (selectedIndex == null ||
      selectedIndex < 0 ||
      selectedIndex >= actions.length) {
    return;
  }
  await actions[selectedIndex].onTap();
}

/// 长按锚点菜单的布局组件。
class AppContextMenu extends StatelessWidget {
  const AppContextMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    this.width = _AppContextMenuMetrics.menuWidth,
  });

  /// 菜单中的操作配置。
  final List<AppContextMenuAction> actions;

  /// 用户点击某一项后的选择回调。
  final ValueChanged<int> onSelected;

  /// 菜单宽度。
  final double width;

  @override
  Widget build(BuildContext context) {
    final hasIcons = actions.any(
      (action) => action.icon != null || action.iconAsset != null,
    );
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r28),
          boxShadow: [
            BoxShadow(
              color: AppColor.x60483A.withValues(alpha: 0.18),
              offset: const Offset(4, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: AppColor.xFFFAF2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r28),
            side: const BorderSide(color: AppColor.xA98B7C, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _AppContextMenuMetrics.menuHorizontalPadding,
              vertical: _AppContextMenuMetrics.menuVerticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < actions.length; index++)
                  _AppContextMenuActionTile(
                    index: index,
                    action: actions[index],
                    hasIcons: hasIcons,
                    onTap: () => onSelected(index),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppContextMenuActionTile extends StatelessWidget {
  const _AppContextMenuActionTile({
    required this.index,
    required this.action,
    required this.hasIcons,
    required this.onTap,
  });

  final int index;
  final AppContextMenuAction action;
  final bool hasIcons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = action.foregroundColor ?? AppColor.x60483A;
    final pressedColor = _AppContextMenuMetrics
        .pressedColors[index % _AppContextMenuMetrics.pressedColors.length];
    final actionRadius = BorderRadius.circular(AppRadius.r12);
    return Semantics(
      button: true,
      label: action.title,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: actionRadius),
        child: InkWell(
          key: ValueKey('app-context-menu-action-$index'),
          borderRadius: actionRadius,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return pressedColor;
            return Colors.transparent;
          }),
          onTap: onTap,
          child: SizedBox(
            width: _AppContextMenuMetrics.actionWidth,
            height: _AppContextMenuMetrics.actionHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hasIcons ? AppSpacing.s8 : AppSpacing.s16,
              ),
              child: Row(
                children: [
                  if (hasIcons) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: action.iconAsset != null
                          ? Image.asset(
                              action.iconAsset!,
                              package: action.iconAssetPackage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            )
                          : action.icon == null
                          ? null
                          : Icon(action.icon, color: foregroundColor, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                  Expanded(
                    child: Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _AppContextMenuLayoutDelegate({
    required this.anchorPosition,
    required this.menuWidth,
  });

  static const edgePadding = AppSpacing.s12;

  final Offset anchorPosition;
  final double menuWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(
      menuWidth,
      math.max(1.0, constraints.maxWidth - edgePadding * 2),
    );
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.max(1.0, constraints.maxHeight - edgePadding * 2),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = anchorPosition.dx <= size.width / 2
        ? anchorPosition.dx
        : anchorPosition.dx - childSize.width;
    final top = anchorPosition.dy <= size.height / 2
        ? anchorPosition.dy
        : anchorPosition.dy - childSize.height;
    return Offset(
      left
          .clamp(
            edgePadding,
            math.max(edgePadding, size.width - childSize.width - edgePadding),
          )
          .toDouble(),
      top
          .clamp(
            edgePadding,
            math.max(edgePadding, size.height - childSize.height - edgePadding),
          )
          .toDouble(),
    );
  }

  @override
  bool shouldRelayout(_AppContextMenuLayoutDelegate oldDelegate) {
    return anchorPosition != oldDelegate.anchorPosition ||
        menuWidth != oldDelegate.menuWidth;
  }
}

abstract final class _AppContextMenuMetrics {
  static const pressedColors = [
    Color(0xFFF5E8DA),
    Color(0xFFE9EFE5),
    Color(0xFFF7E2DB),
  ];
  static const actionWidth = 144.0;
  static const actionHeight = 40.0;
  static const menuHorizontalPadding = AppSpacing.s16;
  static const menuVerticalPadding = AppSpacing.s8;
  static const menuWidth = actionWidth + menuHorizontalPadding * 2;
}
