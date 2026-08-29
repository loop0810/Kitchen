import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_size.dart';
import '../foundation/kitchen_design_app_spacing.dart';
import '../foundation/kitchen_design_app_text.dart';

/// 图标在按钮文字前方或后方的位置。
enum AppImportButtonIconPosition { leading, trailing }

/// 厨房手记风格的导入操作按钮。
///
/// 按钮始终使用边框、珊瑚色填充和偏移阴影。图标为空时只渲染文字，不会
/// 保留图标或图标间距占位。
class AppImportButton extends StatelessWidget {
  const AppImportButton({
    super.key,
    required this.onPressed,
    this.label = '导入菜谱',
    this.icon,
    this.iconPosition = AppImportButtonIconPosition.leading,
    this.height = AppSize.buttonHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
    this.iconSize = AppSize.icon20,
    this.fontSize = AppText.body,
  });

  /// 点击按钮时执行的回调；为空时按钮不可用。
  final VoidCallback? onPressed;

  /// 按钮显示的文字。
  final String label;

  /// 可选的 Material 图标；为空时不显示图标。
  final IconData? icon;

  /// 图标相对于文字的位置。
  final AppImportButtonIconPosition iconPosition;

  /// 按钮的最小高度。
  final double height;

  /// 按钮内容的内边距；不包含图标与文字之间的间距。
  final EdgeInsetsGeometry padding;

  /// 图标尺寸。
  final double iconSize;

  /// 按钮文字字号。
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r12);
    final content = <Widget>[];
    if (icon != null && iconPosition == AppImportButtonIconPosition.leading) {
      content.add(Icon(icon, size: iconSize, color: AppColor.xFFFFFF));
      content.add(const SizedBox(width: AppSpacing.s8));
    }
    content.add(Text(label));
    if (icon != null && iconPosition == AppImportButtonIconPosition.trailing) {
      content.add(const SizedBox(width: AppSpacing.s8));
      content.add(Icon(icon, size: iconSize, color: AppColor.xFFFFFF));
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: AppColor.xA94B3F,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: AppColor.xF26A58,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: AppColor.xA94B3F, width: 2),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Padding(
                padding: padding,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: AppColor.xFFFFFF,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: content,
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
