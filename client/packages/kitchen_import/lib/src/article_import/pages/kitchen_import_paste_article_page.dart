import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

import '../../shared/providers/kitchen_import_dependencies.dart';

class PasteArticlePage extends ConsumerStatefulWidget {
  const PasteArticlePage({super.key});

  @override
  ConsumerState<PasteArticlePage> createState() => _PasteArticlePageState();
}

class _PasteArticlePageState extends ConsumerState<PasteArticlePage> {
  final _controller = TextEditingController();
  var _saving = false;
  var _allowPop = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = '请先粘贴文章或链接');
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final dependencies = ref.read(importDependenciesProvider);
      // 只有 Repository 完成原文持久化并返回 taskId 后，才启动后续解析。
      final taskId = await dependencies.repository.createTextTask(text);
      // 后续解析在后台推进，失败状态由导入任务页展示；这里只负责不丢错误。
      unawaited(
        dependencies.pipeline
            .process(taskId)
            .then<void>(
              (_) {},
              onError: (Object error, StackTrace stackTrace) => developer.log(
                'process_text_import_failed',
                name: 'kitchen_import',
                error: error,
                stackTrace: stackTrace,
              ),
            ),
      );
      if (mounted) {
        _allowPop = true;
        context.replaceWithImportTask(taskId);
      }
    } catch (error, stackTrace) {
      developer.log(
        'create_text_import_task_failed',
        name: 'kitchen_import',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _errorText = '原始内容保存失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃未保存的内容？'),
        content: const Text('当前文章或链接尚未保存到导入箱。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _controller.text.trim().isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('粘贴文章或链接')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Text(
              '粘贴完整文章、分享文案或公开 HTTPS 链接。原文会先保存在本机。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 12,
              maxLines: null,
              onChanged: (_) => setState(() => _errorText = null),
              decoration: InputDecoration(
                labelText: '文章或链接',
                alignLabelWithHint: true,
                hintText: '在这里粘贴内容…',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: AppSize.icon18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_saving ? '正在保存…' : '保存并整理'),
            ),
          ],
        ),
      ),
    );
  }
}
