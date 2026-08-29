import 'dart:async';

import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_spacing.dart';

/// 底部选择面板中的一个可选操作。
class AppActionSheetAction {
  const AppActionSheetAction({
    required this.title,
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.iconAssetPackage,
    this.subtitle,
    this.iconBackgroundColor,
    this.iconColor,
  }) : assert(
         icon != null || iconAsset != null,
         'icon and iconAsset cannot both be null',
       ),
       assert(
         icon == null || iconAsset == null,
         'icon and iconAsset cannot both be provided',
       ),
       assert(
         iconAssetPackage == null || iconAsset != null,
         'iconAssetPackage requires iconAsset',
       );

  /// 操作卡片左侧的 Material 图标。
  final IconData? icon;

  /// 操作卡片左侧的资源图片路径；适合使用设计稿提供的图标资源。
  final String? iconAsset;

  /// 资源图片所属的 package；为空时从当前应用资源中加载。
  final String? iconAssetPackage;

  /// 操作卡片主标题。
  final String title;

  /// 操作卡片可选的辅助说明。
  final String? subtitle;

  /// 选中操作后执行的回调。
  final FutureOr<void> Function() onTap;

  /// 图标容器背景色；未提供时使用面板默认粉色。
  final Color? iconBackgroundColor;

  /// 图标前景色；未提供时使用面板默认珊瑚色。
  final Color? iconColor;
}

/// 展示通用底部选择面板。
Future<void> showAppActionSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<AppActionSheetAction> actions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AppActionSheet(title: title, subtitle: subtitle, actions: actions),
  );
}

/// 通用底部选择面板的可复用展示组件。
class AppActionSheet extends StatelessWidget {
  const AppActionSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.actions,
  });

  /// 面板标题。
  final String title;

  /// 面板副标题；为空时不占用额外布局空间。
  final String? subtitle;

  /// 面板中的可选操作配置。
  final List<AppActionSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.86),
        child: Material(
          color: AppColor.xFFFAF2,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.r28),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s12,
              AppSpacing.s24,
              AppSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _AppActionSheetDragHandle()),
                const SizedBox(height: AppSpacing.s20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColor.x60483A,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColor.x7E756E,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColor.x7E756E,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                for (var index = 0; index < actions.length; index++) ...[
                  _AppActionSheetTile(index: index, action: actions[index]),
                  if (index < actions.length - 1)
                    const SizedBox(height: AppSpacing.s14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppActionSheetDragHandle extends StatelessWidget {
  const _AppActionSheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.s56,
      height: AppSpacing.s6,
      decoration: BoxDecoration(
        color: AppColor.xA98B7C,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
    );
  }
}

class _AppActionSheetTile extends StatelessWidget {
  const _AppActionSheetTile({required this.index, required this.action});

  final int index;
  final AppActionSheetAction action;

  @override
  Widget build(BuildContext context) {
    final label = action.subtitle == null
        ? action.title
        : '${action.title}，${action.subtitle}';
    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        key: ValueKey('app-action-sheet-action-$index'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r22),
          boxShadow: const [
            BoxShadow(
              color: AppColor.xE8DAC1,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: AppColor.xFFFDF8,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r22),
            side: const BorderSide(color: AppColor.xE8DAC1, width: 2),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              unawaited(Future<void>.sync(action.onTap));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20,
                vertical: AppSpacing.s16,
              ),
              child: Row(
                children: [
                  _AppActionSheetIcon(action: action),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColor.x60483A,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (action.subtitle != null) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            action.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColor.x7E756E),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColor.x7E756E,
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

class _AppActionSheetIcon extends StatelessWidget {
  const _AppActionSheetIcon({required this.action});

  final AppActionSheetAction action;

  @override
  Widget build(BuildContext context) {
    if (action.iconAsset != null) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Image.asset(
          action.iconAsset!,
          package: action.iconAssetPackage,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: action.iconBackgroundColor ?? AppColor.xF5DDD5,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Icon(
        action.icon!,
        color: action.iconColor ?? AppColor.xA94B3F,
        size: 24,
      ),
    );
  }
}
