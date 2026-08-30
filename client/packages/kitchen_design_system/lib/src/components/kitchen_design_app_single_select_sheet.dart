import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_size.dart';
import '../foundation/kitchen_design_app_spacing.dart';

/// 底部单选面板中的一个选项。
class AppSingleSelectSheetOption<T> {
  const AppSingleSelectSheetOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconAsset,
    this.iconAssetPackage,
    this.iconBackgroundColor,
    this.iconColor,
  }) : assert(
         icon == null || iconAsset == null,
         'icon and iconAsset cannot both be provided',
       ),
       assert(
         iconAssetPackage == null || iconAsset != null,
         'iconAssetPackage requires iconAsset',
       );

  /// 选项对应的业务值。
  final T value;

  /// 选项主标题。
  final String title;

  /// 选项可选的辅助说明。
  final String? subtitle;

  /// 选项左侧的 Material 图标。
  final IconData? icon;

  /// 选项左侧的资源图片路径。
  final String? iconAsset;

  /// 资源图片所属的 package；为空时从当前应用资源中加载。
  final String? iconAssetPackage;

  /// 图标容器背景色；未提供时使用面板默认粉色。
  final Color? iconBackgroundColor;

  /// 图标前景色；未提供时使用面板默认珊瑚色。
  final Color? iconColor;
}

/// 展示通用底部单选面板，并在用户选中一项后返回其业务值。
Future<T?> showAppSingleSelectSheet<T>({
  required BuildContext context,
  String? title,
  String? subtitle,
  required List<AppSingleSelectSheetOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppSingleSelectSheet<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      selected: selected,
    ),
  );
}

/// 通用底部单选面板的可复用展示组件。
class AppSingleSelectSheet<T> extends StatelessWidget {
  const AppSingleSelectSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.options,
    this.selected,
  }) : assert(options.length > 0, 'options cannot be empty');

  /// 面板标题；为空时不显示标题。
  final String? title;

  /// 面板副标题；为空时不显示副标题。
  final String? subtitle;

  /// 面板中的单选项配置。
  final List<AppSingleSelectSheetOption<T>> options;

  /// 当前选中的业务值；为空表示当前没有选项被选中。
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final hasTitle = title?.trim().isNotEmpty ?? false;
    final hasSubtitle = subtitle?.trim().isNotEmpty ?? false;
    final hasHeaderText = hasTitle || hasSubtitle;

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
                const Center(child: _AppSingleSelectSheetDragHandle()),
                const SizedBox(height: AppSpacing.s20),
                Row(
                  mainAxisAlignment: hasHeaderText
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasHeaderText)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasTitle)
                              Text(
                                title!,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColor.x60483A,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (hasTitle && hasSubtitle)
                              const SizedBox(height: AppSpacing.s8),
                            if (hasSubtitle)
                              Text(
                                subtitle!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColor.x7E756E,
                                ),
                              ),
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
                RadioGroup<T>(
                  groupValue: selected,
                  onChanged: (value) {
                    if (value != null) Navigator.of(context).pop(value);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < options.length; index++) ...[
                        _AppSingleSelectSheetTile<T>(
                          index: index,
                          option: options[index],
                          selected: options[index].value == selected,
                        ),
                        if (index < options.length - 1)
                          const SizedBox(height: AppSpacing.s14),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSingleSelectSheetDragHandle extends StatelessWidget {
  const _AppSingleSelectSheetDragHandle();

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

class _AppSingleSelectSheetTile<T> extends StatelessWidget {
  const _AppSingleSelectSheetTile({
    required this.index,
    required this.option,
    required this.selected,
  });

  final int index;
  final AppSingleSelectSheetOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final subtitle = option.subtitle?.trim();
    final label = subtitle == null || subtitle.isEmpty
        ? option.title
        : '${option.title}，$subtitle';
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      child: DecoratedBox(
        key: ValueKey('app-single-select-sheet-option-$index'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r22),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: AppColor.xE8DAC1,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: selected
              ? AppColor.xF5D477.withValues(alpha: 0.32)
              : AppColor.xFFFDF8,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r22),
            side: BorderSide(
              color: selected ? AppColor.x60483A : AppColor.xE8DAC1,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(option.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20,
                vertical: AppSpacing.s16,
              ),
              child: Row(
                children: [
                  if (option.icon != null || option.iconAsset != null) ...[
                    _AppSingleSelectSheetIcon(option: option),
                    const SizedBox(width: AppSpacing.s16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColor.x60483A,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (option.subtitle?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            option.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColor.x7E756E),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: AppSize.icon30,
                    height: AppSize.icon30,
                    child: Radio<T>(
                      value: option.value,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected)
                            ? AppColor.x60483A
                            : AppColor.x7E756E;
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
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

class _AppSingleSelectSheetIcon<T> extends StatelessWidget {
  const _AppSingleSelectSheetIcon({required this.option});

  final AppSingleSelectSheetOption<T> option;

  @override
  Widget build(BuildContext context) {
    if (option.iconAsset != null) {
      return SizedBox(
        width: AppSize.icon44,
        height: AppSize.icon44,
        child: Image.asset(
          option.iconAsset!,
          package: option.iconAssetPackage,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return Container(
      width: AppSize.icon44,
      height: AppSize.icon44,
      decoration: BoxDecoration(
        color: option.iconBackgroundColor ?? AppColor.xF5DDD5,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Icon(
        option.icon!,
        color: option.iconColor ?? AppColor.xA94B3F,
        size: 24,
      ),
    );
  }
}
