import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

/// 菜谱集创建或编辑弹框的提交结果。
class CollectionEditorResult {
  const CollectionEditorResult({required this.name, required this.coverChange});

  /// 去除首尾空格并通过长度校验的菜谱集名称。
  final String name;

  /// 用户对自定义封面的类型化变更。
  final RecipeCollectionCoverChange coverChange;
}

Future<CollectionEditorResult?> showCollectionEditorDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  Uint8List? initialCoverBytes,
}) => showDialog<CollectionEditorResult>(
  context: context,
  builder: (context) => _CollectionEditorDialog(
    title: title,
    initialName: initialName,
    initialCoverBytes: initialCoverBytes,
  ),
);

class _CollectionEditorDialog extends StatefulWidget {
  const _CollectionEditorDialog({
    required this.title,
    required this.initialName,
    required this.initialCoverBytes,
  });

  final String title;
  final String initialName;
  final Uint8List? initialCoverBytes;

  @override
  State<_CollectionEditorDialog> createState() =>
      _CollectionEditorDialogState();
}

class _CollectionEditorDialogState extends State<_CollectionEditorDialog> {
  late final TextEditingController _controller;
  late Uint8List? _previewBytes;
  RecipeCollectionCoverChange _coverChange =
      const RecipeCollectionCoverChange.keep();
  String? _errorText;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _previewBytes = widget.initialCoverBytes;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: '菜谱集名称',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.s8),
          Semantics(
            label: _previewBytes == null ? '默认菜谱集封面' : '自定义菜谱集封面预览',
            image: true,
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r12),
                child: _previewBytes == null
                    ? ColoredBox(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.auto_stories_rounded, size: 48),
                      )
                    : Image.memory(
                        _previewBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: AppColor.xFFFAF2,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s8,
            children: [
              TextButton.icon(
                onPressed: _isPicking ? null : _pickAndCrop,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_previewBytes == null ? '选择封面' : '更换封面'),
              ),
              if (_previewBytes != null)
                TextButton.icon(
                  onPressed: _isPicking ? null : _recropCurrent,
                  icon: const Icon(Icons.crop_rounded),
                  label: const Text('重新裁切'),
                ),
              if (_previewBytes != null)
                TextButton.icon(
                  onPressed: _isPicking ? null : _removeCover,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('恢复默认'),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isPicking ? null : () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _isPicking ? null : _submit,
        child: const Text('保存'),
      ),
    ],
  );

  Future<void> _pickAndCrop() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    await _cropPath(picked.path);
  }

  Future<void> _recropCurrent() async {
    final bytes = _previewBytes;
    if (bytes == null) return;
    final temporary = File(
      '${Directory.systemTemp.path}/kitchen_collection_cover_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await _cropPath(temporary.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _cropPath(String path) async {
    setState(() => _isPicking = true);
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        maxWidth: 900,
        maxHeight: 1200,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 88,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: '裁切菜谱集封面', lockAspectRatio: true),
          IOSUiSettings(
            title: '裁切菜谱集封面',
            doneButtonTitle: '完成',
            cancelButtonTitle: '取消',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null || !mounted) return;
      final bytes = await cropped.readAsBytes();
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _coverChange = RecipeCollectionCoverChange.replace(bytes);
      });
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeCover() {
    setState(() {
      _previewBytes = null;
      _coverChange = const RecipeCollectionCoverChange.remove();
    });
  }

  void _submit() {
    try {
      final name = normalizeRecipeCollectionName(_controller.text);
      Navigator.pop(
        context,
        CollectionEditorResult(name: name, coverChange: _coverChange),
      );
    } on ArgumentError catch (error) {
      setState(() => _errorText = error.message?.toString());
    }
  }
}
