import 'package:flutter/material.dart';

/// 统一的轻量提示入口，取代各 Feature 手写的 `ScaffoldMessenger` 与 `SnackBar` 组合。
///
/// [replaceCurrent] 用于表单校验等会连续触发提示的场景，先收起当前提示避免排队。
void showKitchenMessage(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  bool replaceCurrent = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (replaceCurrent) messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message), action: action));
}
