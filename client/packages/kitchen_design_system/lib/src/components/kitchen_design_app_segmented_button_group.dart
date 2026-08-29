import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_size.dart';
import '../foundation/kitchen_design_app_spacing.dart';
import '../foundation/kitchen_design_app_text.dart';
import 'kitchen_design_app_scrapbook_button.dart';

/// 分段按钮组中的一个文字选项。
class AppSegmentedButtonOption<T> {
  const AppSegmentedButtonOption({required this.value, required this.label});

  /// 选项对应的业务值。
  final T value;

  /// 选项显示的文字。
  final String label;
}

/// 厨房手记风格的文字分段按钮组。
///
/// 未选中项只有边框和文字，选中项使用珊瑚色填充并带有手账风格的偏移
/// 阴影。当前组件只接受文字选项，暂不提供图标插槽。
class AppSegmentedButtonGroup<T> extends StatelessWidget {
  const AppSegmentedButtonGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = AppSize.buttonHeight,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s20,
      vertical: AppSpacing.s8,
    ),
    this.spacing = AppSpacing.s8,
    this.fontSize = AppText.body,
  }) : assert(options.length > 0, 'options cannot be empty');

  /// 可供选择的文字选项。
  final List<AppSegmentedButtonOption<T>> options;

  /// 当前选中的业务值。
  final T selected;

  /// 选项改变时回调新的业务值。
  final ValueChanged<T> onChanged;

  /// 每个按钮的最小高度。
  final double height;

  /// 每个按钮内容的内边距；不包含选项之间的间距。
  final EdgeInsetsGeometry padding;

  /// 按钮之间的水平间距。
  final double spacing;

  /// 按钮文字字号。
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) SizedBox(width: spacing),
          Semantics(
            selected: options[index].value == selected,
            child: AppScrapbookButton(
              key: ValueKey('app-scrapbook-button-$index'),
              label: options[index].label,
              filled: options[index].value == selected,
              onPressed: () => onChanged(options[index].value),
              height: height,
              padding: padding,
              fontSize: fontSize,
            ),
          ),
        ],
      ],
    );
  }
}
