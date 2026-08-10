import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import '../../shared/providers/kitchen_import_dependencies.dart';

class ImportMediaWorkspaceWidget extends ConsumerStatefulWidget {
  const ImportMediaWorkspaceWidget({
    super.key,
    required this.taskId,
    required this.media,
  });

  final String taskId;
  final List<ImportMediaReference> media;

  @override
  ConsumerState<ImportMediaWorkspaceWidget> createState() =>
      _ImportMediaWorkspaceWidgetState();
}

class _ImportMediaWorkspaceWidgetState
    extends ConsumerState<ImportMediaWorkspaceWidget> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final ordered = [...widget.media]
      ..sort((left, right) => left.position.compareTo(right.position));
    return Semantics(
      container: true,
      label: '导入图片管理，共 ${ordered.length} 张',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '图片与识别状态',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : _append,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          SizedBox(
            height: 292,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: ordered.length,
              onReorderItem: _busy
                  ? (_, _) {}
                  : (oldIndex, newIndex) =>
                        _reorder(ordered, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final item = ordered[index];
                return _MediaCard(
                  key: ValueKey(item.id),
                  item: item,
                  index: index,
                  busy: _busy,
                  onZoom: () => _zoom(item),
                  onReplace: () => _replace(item),
                  onCrop: () => _crop(item),
                  onRotate: () => _run(
                    () => ref
                        .read(importDependenciesProvider)
                        .repository
                        .rotateMedia(widget.taskId, item.id),
                  ),
                  onToggleIgnored: () => _run(
                    () => ref
                        .read(importDependenciesProvider)
                        .repository
                        .setMediaIgnored(widget.taskId, item.id, !item.ignored),
                  ),
                  onRetry:
                      !item.ignored &&
                          item.ocrStatus == ImportMediaOcrStatus.failed
                      ? () => _run(
                          () => ref
                              .read(importDependenciesProvider)
                              .repository
                              .retryMediaOcr(widget.taskId, item.id),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _append() async {
    final selected = await ImagePicker().pickMultiImage();
    if (selected.isEmpty || !mounted) return;
    await _run(() async {
      final dependencies = ref.read(importDependenciesProvider);
      final paths = await dependencies.persistPickedImages(
        selected.map((item) => item.path).toList(growable: false),
      );
      await dependencies.repository.appendMedia(widget.taskId, paths);
    });
  }

  Future<void> _replace(ImportMediaReference media) async {
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selected == null || !mounted) return;
    await _run(() async {
      final dependencies = ref.read(importDependenciesProvider);
      final paths = await dependencies.persistPickedImages([selected.path]);
      await dependencies.repository.replaceMedia(
        taskId: widget.taskId,
        mediaId: media.id,
        controlledLocalPath: paths.single,
      );
    });
  }

  Future<void> _crop(ImportMediaReference media) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: media.localPath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪菜谱图片',
          // 菜谱原图比例不固定，允许用户分别拖动四条边和四个角。
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(
          title: '裁剪菜谱图片',
          doneButtonTitle: '完成',
          cancelButtonTitle: '取消',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;
    await _run(() async {
      final dependencies = ref.read(importDependenciesProvider);
      final paths = await dependencies.persistPickedImages([cropped.path]);
      await dependencies.repository.submitCroppedMedia(
        taskId: widget.taskId,
        mediaId: media.id,
        controlledLocalPath: paths.single,
      );
    });
  }

  Future<void> _reorder(
    List<ImportMediaReference> ordered,
    int oldIndex,
    int newIndex,
  ) async {
    final changed = [...ordered];
    changed.insert(newIndex, changed.removeAt(oldIndex));
    await _run(
      () => ref
          .read(importDependenciesProvider)
          .repository
          .reorderMedia(
            widget.taskId,
            changed.map((item) => item.id).toList(growable: false),
          ),
    );
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
      if (!mounted) return;
      final dependencies = ref.read(importDependenciesProvider);
      ref.invalidate(importTaskProvider(widget.taskId));
      unawaited(dependencies.pipeline.process(widget.taskId));
    } catch (_) {
      if (!mounted) return;
      showKitchenMessage(context, '图片操作失败，原内容已保留，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _zoom(ImportMediaReference media) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text('图片 ${media.position + 1}')),
          body: Semantics(
            label: '可缩放的菜谱图片 ${media.position + 1}',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Center(child: Image.file(File(media.localPath))),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    super.key,
    required this.item,
    required this.index,
    required this.busy,
    required this.onZoom,
    required this.onReplace,
    required this.onCrop,
    required this.onRotate,
    required this.onToggleIgnored,
    this.onRetry,
  });

  final ImportMediaReference item;
  final int index;
  final bool busy;
  final VoidCallback onZoom;
  final VoidCallback onReplace;
  final VoidCallback onCrop;
  final VoidCallback onRotate;
  final VoidCallback onToggleIgnored;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        margin: const EdgeInsets.only(right: AppSpacing.s8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InkWell(
                      onTap: onZoom,
                      child: Semantics(
                        button: true,
                        label: '查看并缩放第 ${index + 1} 张图片',
                        child: Transform.rotate(
                          angle: item.rotationQuarterTurns * math.pi / 2,
                          child: Image.file(
                            File(item.localPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppColor.paper,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (item.ignored)
                      const ColoredBox(
                        color: Color(0x99000000),
                        child: Center(
                          child: Text(
                            '已忽略',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: ReorderableDragStartListener(
                        index: index,
                        enabled: !busy,
                        child: const Tooltip(
                          message: '拖动调整顺序',
                          child: Icon(Icons.drag_indicator_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                '第 ${index + 1} 张 · ${_ocrStatusText(item)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.ocrErrorMessage != null)
                Text(
                  item.ocrErrorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    onPressed: busy ? null : onReplace,
                    tooltip: '替换图片',
                    icon: const Icon(Icons.find_replace_outlined),
                  ),
                  IconButton(
                    onPressed: busy ? null : onCrop,
                    tooltip: '裁剪图片',
                    icon: const Icon(Icons.crop_outlined),
                  ),
                  IconButton(
                    onPressed: busy ? null : onRotate,
                    tooltip: '顺时针旋转 90 度',
                    icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                  ),
                  IconButton(
                    onPressed: busy ? null : onToggleIgnored,
                    tooltip: item.ignored ? '恢复这张图片' : '忽略这张图片',
                    icon: Icon(
                      item.ignored
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  if (onRetry != null)
                    IconButton(
                      onPressed: busy ? null : onRetry,
                      tooltip: '仅重试这张图片',
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _ocrStatusText(ImportMediaReference media) {
  if (media.ignored) return '不参与整理';
  return switch (media.ocrStatus) {
    ImportMediaOcrStatus.pending => '等待识别',
    ImportMediaOcrStatus.processing => '识别中',
    ImportMediaOcrStatus.succeeded => '识别成功',
    ImportMediaOcrStatus.failed => '识别失败',
  };
}
