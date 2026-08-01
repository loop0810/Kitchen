import 'package:flutter/material.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import 'kitchen_import_dependencies.dart';

bool _isProcessing(ImportTaskStatus status) => {
  ImportTaskStatus.queued,
  ImportTaskStatus.extracting,
  ImportTaskStatus.recognizingImages,
  ImportTaskStatus.structuring,
}.contains(status);

/// 显示按任务状态区分的确认文案，并执行取消及删除的统一流程。
Future<bool> confirmAndDeleteImportTask(
  BuildContext context, {
  required ImportDependencies dependencies,
  required ImportTaskEntity task,
}) async {
  final description = switch (task.status) {
    ImportTaskStatus.saved => '只会删除这条导入记录，不会删除已经保存到菜谱库的正式菜谱。',
    ImportTaskStatus.queued ||
    ImportTaskStatus.extracting ||
    ImportTaskStatus.recognizingImages ||
    ImportTaskStatus.structuring => '正在进行的处理会停止，原始内容、中间结果和受控图片会一并删除。',
    _ => '原始内容、中间结果和受控图片会一并删除。',
  };
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除导入任务？'),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('保留'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  if (_isProcessing(task.status)) {
    try {
      await dependencies.repository.cancel(task.id);
    } on StateError {
      // 任务可能已经被另一个入口删除，后续 delete 保持幂等。
    }
  }
  await dependencies.repository.delete(task.id);
  return true;
}
