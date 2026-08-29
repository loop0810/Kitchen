import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_size.dart';
import '../foundation/kitchen_design_app_spacing.dart';
import '../foundation/kitchen_design_app_text.dart';

/// 手账视觉风格的通用按钮。
///
/// 组件只负责统一按钮视觉。通过 [filled] 选择填充或未填充样式，业务层
/// 可以在应用的任意位置使用它，而不引入筛选或分段控制语义。
class AppScrapbookButton extends StatelessWidget {
  const AppScrapbookButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onPressed,
    this.height = AppSize.buttonHeight,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s20,
      vertical: AppSpacing.s12,
    ),
    this.fontSize = AppText.body,
  });

  /// 按钮显示的文字。
  final String label;

  /// 是否使用填充样式；为 false 时只显示边框。
  final bool filled;

  /// 点击按钮时执行的回调；为空时按钮不可用。
  final VoidCallback? onPressed;

  /// 按钮的最小高度。
  final double height;

  /// 按钮内容的内边距。
  final EdgeInsetsGeometry padding;

  /// 按钮文字字号。
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r12);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: AppColor.xA94B3F,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: filled ? AppColor.xF26A58 : Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: filled ? AppColor.xA94B3F : AppColor.xE8DAC1,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Padding(
                padding: padding,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: filled ? AppColor.xFFFFFF : AppColor.x60483A,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
