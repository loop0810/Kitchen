import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import 'kitchen_import_dependencies.dart';

class ImportInboxPage extends ConsumerWidget {
  const ImportInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(importTasksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入箱'),
        actions: [
          IconButton(
            tooltip: '创建食谱',
            onPressed: context.showRecipeCreationOptions,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: tasks.when(
        data: (items) => items.isEmpty
            ? _EmptyInbox(onCreate: context.showRecipeCreationOptions)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(importTasksProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s8),
                  itemBuilder: (context, index) {
                    final task = items[index];
                    return _TaskCard(
                      task: task,
                      onTap: () => context.pushImportTask(task.id),
                    );
                  },
                ),
              ),
        error: (_, _) => const Center(child: Text('导入任务加载失败，请稍后重试')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: tasks.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              tooltip: '创建食谱',
              onPressed: context.showRecipeCreationOptions,
              icon: const Icon(Icons.add_rounded),
              label: const Text('创建食谱'),
            )
          : null,
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final ImportTaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = _statusPresentation(task.status);
    final title = task.draft?.title.value.trim().isNotEmpty == true
        ? task.draft!.title.value
        : task.originalText.split('\n').firstOrNull?.trim().isNotEmpty == true
        ? task.originalText.split('\n').first.trim()
        : task.media.isNotEmpty
        ? '${task.media.length} 张图片'
        : '未命名导入';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: AppSpacing.s12,
        leading: CircleAvatar(
          child: Icon(
            task.media.isEmpty
                ? Icons.article_outlined
                : Icons.photo_library_outlined,
          ),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(state.$1),
        trailing: Icon(state.$2, color: state.$3),
      ),
    );
  }
}

(String, IconData, Color) _statusPresentation(ImportTaskStatus status) {
  return switch (status) {
    ImportTaskStatus.queued => (
      '等待处理',
      Icons.schedule_rounded,
      AppColor.mutedInk,
    ),
    ImportTaskStatus.extracting => (
      '正在提取',
      Icons.downloading_rounded,
      AppColor.mutedInk,
    ),
    ImportTaskStatus.recognizingImages => (
      '正在识别图片',
      Icons.document_scanner_outlined,
      AppColor.mutedInk,
    ),
    ImportTaskStatus.structuring => (
      '正在整理菜谱',
      Icons.auto_awesome_rounded,
      AppColor.mutedInk,
    ),
    ImportTaskStatus.awaitingReview => (
      '等待确认',
      Icons.fact_check_outlined,
      AppColor.coral,
    ),
    ImportTaskStatus.failed => (
      '处理失败',
      Icons.error_outline_rounded,
      AppColor.coral,
    ),
    ImportTaskStatus.saved => (
      '已保存',
      Icons.check_circle_outline_rounded,
      AppColor.sage,
    ),
    ImportTaskStatus.cancelled => (
      '已取消',
      Icons.cancel_outlined,
      AppColor.mutedInk,
    ),
  };
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: AppColor.blush,
              child: Icon(
                Icons.inbox_rounded,
                size: AppSize.icon36,
                color: AppColor.coral,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              '导入任务会出现在这里',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s8),
            const Text('从其他 App 分享的内容也会直接进入导入箱。', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.s24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('创建食谱'),
            ),
          ],
        ),
      ),
    );
  }
}
