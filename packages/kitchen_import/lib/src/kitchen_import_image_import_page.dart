import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';

import 'kitchen_import_dependencies.dart';

class ImageImportPage extends ConsumerStatefulWidget {
  const ImageImportPage({super.key});

  @override
  ConsumerState<ImageImportPage> createState() => _ImageImportPageState();
}

class _ImageImportPageState extends ConsumerState<ImageImportPage> {
  var _picking = false;
  var _openedPicker = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_openedPicker) {
      _openedPicker = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _pick());
    }
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final selected = await ImagePicker().pickMultiImage();
      if (selected.isEmpty) return;
      final dependencies = ref.read(importDependenciesProvider);
      final controlledPaths = await dependencies.persistPickedImages(
        selected.map((image) => image.path).toList(growable: false),
      );
      // 文件全部复制成功后才创建任务，防止任务引用相册临时路径。
      final taskId = await dependencies.repository.createImageTask(
        controlledPaths,
      );
      unawaited(dependencies.pipeline.process(taskId));
      if (mounted) {
        context.replaceWithImportTask(taskId);
      }
    } catch (_) {
      if (mounted) setState(() => _error = '图片保存失败，请重新选择');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择图片')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: AppSize.icon58,
                color: AppColor.coral,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                _picking ? '正在保存图片…' : '可从相册选择一张或多张图片',
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(_error!, style: const TextStyle(color: AppColor.coral)),
              ],
              const SizedBox(height: AppSpacing.s20),
              FilledButton.icon(
                onPressed: _picking ? null : _pick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('选择图片'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
