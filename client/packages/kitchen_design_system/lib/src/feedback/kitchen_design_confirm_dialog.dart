import 'package:flutter/material.dart';

/// 各 Feature 通用的二次确认弹窗：取消返回 `false`，确认返回 `true`。
///
/// 弹窗被系统返回手势或点击遮罩关闭时同样返回 `false`，调用方不需要再区分
/// `null` 与显式取消。弹窗使用自身的 `dialogContext` 关闭，避免调用方页面在
/// 异步等待期间被销毁时误用已失效的 context。
Future<bool> showKitchenConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String cancelLabel = '取消',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
