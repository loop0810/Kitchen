import 'dart:io';
import 'dart:math' as math;
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
}) => _showCollectionEditorDialog(
  context,
  title: title,
  initialName: initialName,
  initialCoverBytes: initialCoverBytes,
);

/// 展示创建菜谱集时使用的手账风格弹框。
Future<CollectionEditorResult?> showCollectionCreationDialog(
  BuildContext context,
) => _showCollectionEditorDialog(context, title: '创建菜谱集', creationStyle: true);

Future<CollectionEditorResult?> _showCollectionEditorDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
  Uint8List? initialCoverBytes,
  bool creationStyle = false,
}) => showDialog<CollectionEditorResult>(
  context: context,
  builder: (context) => _CollectionEditorDialog(
    title: title,
    initialName: initialName,
    initialCoverBytes: initialCoverBytes,
    creationStyle: creationStyle,
  ),
);

class _CollectionEditorDialog extends StatefulWidget {
  const _CollectionEditorDialog({
    required this.title,
    required this.initialName,
    required this.initialCoverBytes,
    required this.creationStyle,
  });

  final String title;
  final String initialName;
  final Uint8List? initialCoverBytes;
  final bool creationStyle;

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
  Widget build(BuildContext context) => widget.creationStyle
      ? _buildCreationDialog(context)
      : _buildEditorDialog(context);

  Widget _buildEditorDialog(BuildContext context) => AlertDialog(
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

  Widget _buildCreationDialog(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r18);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColor.xFFFAF2,
          borderRadius: radius,
          border: Border.all(color: AppColor.xA98B7C, width: AppSpacing.s3),
          boxShadow: const [
            BoxShadow(
              color: AppColor.xA98B7C,
              offset: Offset(0, AppSpacing.s4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s28,
              AppSpacing.s24,
              AppSpacing.s24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColor.x60483A,
                        fontSize: AppText.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: 40,
                      decoration: InputDecoration(
                        hintText: '请输入菜谱集名称',
                        hintStyle: const TextStyle(
                          color: AppColor.xA98B7C,
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w600,
                        ),
                        errorText: _errorText,
                        counterText: '',
                        filled: true,
                        fillColor: AppColor.xFFFDF8,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20,
                          vertical: AppSpacing.s16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r18),
                          borderSide: const BorderSide(
                            color: AppColor.xA98B7C,
                            width: AppSpacing.s3,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r18),
                          borderSide: const BorderSide(
                            color: AppColor.xA98B7C,
                            width: AppSpacing.s3,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r18),
                          borderSide: const BorderSide(
                            color: AppColor.xF26A58,
                            width: AppSpacing.s3,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    _buildCreationCoverPicker(),
                    const SizedBox(height: AppSpacing.s48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppScrapbookButton(
                          label: '取消',
                          filled: false,
                          onPressed: _isPicking
                              ? null
                              : () => Navigator.pop(context),
                          height: AppSize.buttonHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s16),
                        AppScrapbookButton(
                          label: '创建',
                          filled: true,
                          onPressed: _isPicking ? null : _submit,
                          height: AppSize.buttonHeight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreationCoverPicker() {
    final hasCover = _previewBytes != null;
    final radius = BorderRadius.circular(AppRadius.r16);
    return Semantics(
      button: true,
      label: hasCover ? '更换封面图片' : '设置封面图片，可选',
      child: CustomPaint(
        painter: const _DashedRoundedBorderPainter(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isPicking ? null : _pickAndCrop,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: Row(
                  children: [
                    Icon(
                      hasCover
                          ? Icons.photo_rounded
                          : Icons.add_photo_alternate_outlined,
                      color: AppColor.xF26A58,
                      size: AppSize.icon30,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        hasCover ? '更换封面图片' : '设置封面图片',
                        style: const TextStyle(
                          color: AppColor.x60483A,
                          fontSize: AppText.title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_isPicking)
                      const SizedBox(
                        width: AppSize.icon20,
                        height: AppSize.icon20,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.s3,
                          color: AppColor.xF26A58,
                        ),
                      )
                    else
                      Text(
                        hasCover ? '已设置' : '可选',
                        style: const TextStyle(
                          color: AppColor.xA98B7C,
                          fontSize: AppText.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.r16),
        ),
      );
    final paint = Paint()
      ..color = AppColor.xE8DAC1
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSpacing.s3;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + AppSpacing.s8, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += AppSpacing.s16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
