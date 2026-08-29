import 'package:flutter/material.dart';

import '../foundation/kitchen_design_app_color.dart';
import '../foundation/kitchen_design_app_radius.dart';
import '../foundation/kitchen_design_app_spacing.dart';
import '../foundation/kitchen_design_app_text.dart';
import 'kitchen_design_app_scrapbook_button.dart';

/// 通用弹窗中的一个操作。
class AppDialogAction {
  const AppDialogAction({required this.title, required this.onPressed});

  /// 操作按钮的标题。
  final String title;

  /// 点击操作后的回调；需要返回结果时由回调负责关闭弹窗并传值。
  final VoidCallback onPressed;
}

/// 展示遵循厨房手记视觉规范的通用弹窗。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required List<AppDialogAction> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => AppDialog(title: title, content: content, actions: actions),
  );
}

/// 通用弹窗组件。
///
/// 正文使用单个 [Text] 渲染，以保证多行内容颜色统一，并由 Flutter 根据
/// 弹窗可用宽度自动换行。最后一个操作始终作为强调操作显示。
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  }) : assert(actions.length <= _maxActionCount, 'actions cannot exceed 3');

  static const _maxActionCount = 3;

  /// 弹窗标题。
  final String title;

  /// 弹窗正文；支持显式换行和根据可用宽度自动换行。
  final String content;

  /// 弹窗操作，最多支持三个；最后一项为强调操作。
  final List<AppDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s24,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.xFFFDF8,
          borderRadius: BorderRadius.circular(AppRadius.r18),
          boxShadow: [
            BoxShadow(
              color: AppColor.x60483A.withValues(alpha: 0.16),
              offset: const Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(AppRadius.r18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s24,
              AppSpacing.s20,
              AppSpacing.s16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColor.x60483A,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    content,
                    softWrap: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColor.x7E756E,
                      height: 1.5,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var index = 0;
                            index < actions.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: AppSpacing.s8),
                            AppScrapbookButton(
                              key: ValueKey('app-dialog-action-$index'),
                              label: actions[index].title,
                              filled: index == actions.length - 1,
                              onPressed: actions[index].onPressed,
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s16,
                              ),
                              fontSize: AppText.librarySubtitle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
