import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import '../../shared/providers/kitchen_import_dependencies.dart';
import '../widgets/kitchen_import_delete_task_dialog.dart';

class ImportInboxPage extends ConsumerWidget {
  const ImportInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(importTasksProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _InboxHeader(),
            // _InboxViewToggle(emptyState: tasks.value?.isEmpty == true),
            Expanded(
              child: tasks.when(
                data: (items) => items.isEmpty
                    ? const _EmptyInbox()
                    : _TaskList(
                        tasks: items,
                        onRefresh: () async =>
                            ref.invalidate(importTasksProvider),
                        onDelete: (task) => confirmAndDeleteImportTask(
                          context,
                          dependencies: ref.read(importDependenciesProvider),
                          task: task,
                        ),
                      ),
                error: (_, _) => const Center(child: Text('导入任务加载失败，请稍后重试')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s12,
        AppSpacing.s24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导入箱',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColor.x60483A,
              fontSize: AppText.libraryTitle,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          const Text(
            '把纸上与屏幕里的好味道收好',
            style: TextStyle(
              color: AppColor.x7E756E,
              fontSize: AppText.body,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.tasks,
    required this.onRefresh,
    required this.onDelete,
  });

  final List<ImportTaskEntity> tasks;
  final Future<void> Function() onRefresh;
  final ValueChanged<ImportTaskEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24,
          AppSpacing.s20,
          AppSpacing.s24,
          AppSpacing.s24,
        ),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s10),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Slidable(
            key: ValueKey(task.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: [
                SlidableAction(
                  onPressed: (_) => onDelete(task),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  icon: Icons.delete_outline_rounded,
                  label: '删除',
                ),
              ],
            ),
            child: _TaskCard(
              task: task,
              onTap: () => context.pushImportTask(task.id),
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final ImportTaskEntity task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = _statusPresentation(task);
    final title = task.draft?.title.value.trim().isNotEmpty == true
        ? task.draft!.title.value
        : task.originalText.split('\n').firstOrNull?.trim().isNotEmpty == true
        ? task.originalText.split('\n').first.trim()
        : task.media.isNotEmpty
        ? '${task.media.length} 张图片'
        : '未命名导入';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              Image.asset(
                state.assetPath,
                package: 'kitchen_import',
                width: AppSize.icon44,
                height: AppSize.icon44,
                fit: BoxFit.contain,
                semanticLabel: state.label,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColor.x60483A,
                              fontSize: AppText.body,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Text(
                          state.label,
                          style: TextStyle(
                            color: state.color,
                            fontSize: AppText.detail,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      state.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColor.x7E756E,
                        fontSize: AppText.detail,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStatusPresentation {
  const _TaskStatusPresentation({
    required this.assetPath,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  final String assetPath;
  final String label;
  final String subtitle;
  final Color color;
}

_TaskStatusPresentation _statusPresentation(ImportTaskEntity task) {
  final time = _formatTaskTime(task.updatedAt);
  return switch (task.status) {
    ImportTaskStatus.queued => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_processing.png',
      label: '导入中',
      subtitle: '等待处理 · $time',
      color: AppColor.x7E756E,
    ),
    ImportTaskStatus.extracting => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_processing.png',
      label: '导入中',
      subtitle: '正在提取网页内容 · $time',
      color: AppColor.x7E756E,
    ),
    ImportTaskStatus.recognizingImages => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_processing.png',
      label: '导入中',
      subtitle: '正在识别图片 · $time',
      color: AppColor.x7E756E,
    ),
    ImportTaskStatus.structuring => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_processing.png',
      label: '导入中',
      subtitle: '正在整理菜谱 · $time',
      color: AppColor.x7E756E,
    ),
    ImportTaskStatus.awaitingReview => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_review.png',
      label: '等待确认',
      subtitle: '菜谱草稿已生成，请检查食材与步骤',
      color: AppColor.xF26A58,
    ),
    ImportTaskStatus.failed => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_failed.png',
      label: '导入失败',
      subtitle: task.errorMessage?.trim().isNotEmpty == true
          ? task.errorMessage!.trim()
          : '图片文字不够清晰，请更换原图',
      color: AppColor.xF26A58,
    ),
    ImportTaskStatus.saved => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_saved.png',
      label: '已保存',
      subtitle: '菜谱已生成并保存到菜谱库 · $time',
      color: AppColor.xA9B9A2,
    ),
    ImportTaskStatus.cancelled => _TaskStatusPresentation(
      assetPath: 'assets/images/import_inbox_task_status_failed.png',
      label: '已取消',
      subtitle: '任务已取消 · $time',
      color: AppColor.x7E756E,
    ),
  };
}

String _formatTaskTime(DateTime updatedAt) {
  final difference = DateTime.now().difference(updatedAt.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return '刚刚';
  if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
  if (difference.inDays < 1) return '${difference.inHours} 小时前';
  if (difference.inDays == 1) {
    return '昨天 ${_formatClock(updatedAt.toLocal())}';
  }
  final local = updatedAt.toLocal();
  return '${local.month}月${local.day}日';
}

String _formatClock(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          children: [
            Image.asset(
              'assets/images/import_inbox_empty_state.png',
              package: 'kitchen_import',
              width: AppSize.importIllustration,
              height: AppSize.importIllustration,
              fit: BoxFit.contain,
              semanticLabel: '导入箱为空',
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              '导入箱还是空的',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColor.x60483A,
                fontSize: AppText.title,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            const Text(
              '暂时没有导入任务，新的识别进度会在\n这里整理。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.x7E756E,
                fontSize: AppText.body,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
