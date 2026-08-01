import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import 'kitchen_import_dependencies.dart';
import 'kitchen_import_delete_task_dialog.dart';

class ImportTaskPage extends ConsumerWidget {
  const ImportTaskPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(importTaskProvider(taskId));
    return Scaffold(
      appBar: AppBar(title: const Text('导入详情')),
      body: task.when(
        data: (value) {
          if (value == null) return const Center(child: Text('任务不存在或已删除'));
          return _TaskBody(task: value);
        },
        error: (_, _) => const Center(child: Text('任务加载失败')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TaskBody extends ConsumerWidget {
  const _TaskBody({required this.task});

  final ImportTaskEntity task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependencies = ref.read(importDependenciesProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        Text(
          _statusText(task.status),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          task.errorMessage ?? _statusDescription(task.status),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (task.originalText.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s20),
          Text('原始内容', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s8),
          SelectableText(task.originalText, maxLines: 10),
        ],
        if (task.media.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s20),
          Text(
            '已保存 ${task.media.length} 张图片',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
        if (task.ocrText?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '识别文字',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (task.status == ImportTaskStatus.awaitingReview)
                TextButton.icon(
                  onPressed: () => _editOcrText(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('校对'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Semantics(
            label: '图片识别文字',
            child: SelectableText(task.ocrText!, maxLines: 18),
          ),
        ],
        if (task.draft?.warnings.isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.s20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          '本地解析需要确认',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  for (final warning in task.draft!.warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s4),
                      child: Text('• $warning'),
                    ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    '应用只会自动填写有明确本地证据的内容；AI 辅助未来将作为可选付费功能。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        if (task.status == ImportTaskStatus.awaitingReview)
          FilledButton.icon(
            onPressed: () => context.pushReviewImportDraft(task.id),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('继续确认'),
          ),
        if (task.status == ImportTaskStatus.awaitingReview)
          OutlinedButton.icon(
            onPressed: () async {
              await dependencies.pipeline.retry(task.id);
              ref.invalidate(importTaskProvider(task.id));
            },
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: const Text('重新整理'),
          ),
        if (task.status == ImportTaskStatus.failed)
          FilledButton.icon(
            onPressed: () async {
              await dependencies.pipeline.retry(task.id);
              ref.invalidate(importTaskProvider(task.id));
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        if ({
          ImportTaskStatus.queued,
          ImportTaskStatus.extracting,
          ImportTaskStatus.recognizingImages,
          ImportTaskStatus.structuring,
        }.contains(task.status))
          OutlinedButton(
            onPressed: () async {
              await dependencies.repository.cancel(task.id);
              ref.invalidate(importTaskProvider(task.id));
            },
            child: const Text('取消任务'),
          ),
        if (task.status == ImportTaskStatus.cancelled ||
            task.status == ImportTaskStatus.failed)
          TextButton(
            onPressed: () => _delete(context, ref),
            child: const Text('删除任务'),
          ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final deleted = await confirmAndDeleteImportTask(
      context,
      dependencies: ref.read(importDependenciesProvider),
      task: task,
    );
    if (deleted && context.mounted) Navigator.pop(context);
  }

  Future<void> _editOcrText(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: task.ocrText);
    final corrected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('校对识别文字'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 8,
            maxLines: 16,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: '按图片顺序检查菜名、食材和步骤',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('重新整理'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (corrected == null || !context.mounted) return;
    try {
      await ref
          .read(importDependenciesProvider)
          .pipeline
          .restructureFromOcrText(task.id, corrected);
      ref.invalidate(importTaskProvider(task.id));
    } on ImportPipelineException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

String _statusText(ImportTaskStatus status) => switch (status) {
  ImportTaskStatus.queued => '等待处理',
  ImportTaskStatus.extracting => '正在提取网页内容',
  ImportTaskStatus.recognizingImages => '正在识别图片',
  ImportTaskStatus.structuring => '正在整理菜谱',
  ImportTaskStatus.awaitingReview => '草稿等待确认',
  ImportTaskStatus.failed => '处理失败',
  ImportTaskStatus.saved => '已保存到菜谱库',
  ImportTaskStatus.cancelled => '任务已取消',
};

String _statusDescription(ImportTaskStatus status) => switch (status) {
  ImportTaskStatus.queued => '任务已安全保存在本机，即将开始整理。',
  ImportTaskStatus.extracting => '正在读取公开网页，原始链接不会丢失。',
  ImportTaskStatus.recognizingImages => '正在按图片顺序识别文字。',
  ImportTaskStatus.structuring => '正在用本地规则生成可编辑草稿。',
  ImportTaskStatus.awaitingReview => '请检查草稿内容，确认后再保存正式菜谱。',
  ImportTaskStatus.failed => '原始输入仍保存在本机。',
  ImportTaskStatus.saved => '同一任务再次确认不会重复创建菜谱。',
  ImportTaskStatus.cancelled => '可以删除本任务，或保留原始内容。',
};
