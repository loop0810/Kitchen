class OcrRectValueObject {
  const OcrRectValueObject({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// 相对图片宽度归一化后的左边界，范围为 0 到 1。
  final double left;

  /// 相对图片高度归一化后的上边界，范围为 0 到 1。
  final double top;

  /// 相对图片宽度归一化后的右边界，范围为 0 到 1。
  final double right;

  /// 相对图片高度归一化后的下边界，范围为 0 到 1。
  final double bottom;

  /// 文字行中心点的归一化横坐标。
  double get centerX => (left + right) / 2;

  /// 文字行中心点的归一化纵坐标。
  double get centerY => (top + bottom) / 2;

  /// 文字行归一化高度。
  double get height => bottom - top;
}

class OcrLineEntity {
  const OcrLineEntity({
    required this.id,
    required this.text,
    required this.boundingBox,
    this.confidence,
  });

  /// 页面内稳定文字行 ID，用于草稿字段回溯来源。
  final String id;

  /// OCR 识别出的原始文字，不包含结构化阶段的修正。
  final String text;

  /// 文字行在原图中的归一化坐标。
  final OcrRectValueObject boundingBox;

  /// 平台提供的识别置信度，范围为 0 到 1；平台未提供时为空。
  final double? confidence;
}

class OcrPageEntity {
  const OcrPageEntity({
    required this.pageIndex,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.lines,
  });

  /// 用户图片顺序对应的零基页码。
  final int pageIndex;

  /// OCR 输入图片的像素宽度；旧任务无法恢复时为 0。
  final int pixelWidth;

  /// OCR 输入图片的像素高度；旧任务无法恢复时为 0。
  final int pixelHeight;

  /// 页面内带坐标的文字行，原始顺序不作为阅读顺序依据。
  final List<OcrLineEntity> lines;

  /// 按纵向、横向坐标恢复的本页纯文本，用于展示和旧解析兼容。
  String get plainText {
    final ordered = lines.toList(growable: false)
      ..sort((left, right) {
        final vertical = left.boundingBox.top.compareTo(right.boundingBox.top);
        return vertical != 0
            ? vertical
            : left.boundingBox.left.compareTo(right.boundingBox.left);
      });
    return ordered
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
  }

  factory OcrPageEntity.fromPlainText({
    required int pageIndex,
    required String text,
  }) {
    final values = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final divisor = values.isEmpty ? 1 : values.length;
    return OcrPageEntity(
      pageIndex: pageIndex,
      pixelWidth: 0,
      pixelHeight: 0,
      lines: [
        for (final (index, value) in values.indexed)
          OcrLineEntity(
            id: 'legacy-$pageIndex-$index',
            text: value,
            boundingBox: OcrRectValueObject(
              left: 0,
              top: index / divisor,
              right: 1,
              bottom: (index + 1) / divisor,
            ),
          ),
      ],
    );
  }
}

class OcrDocumentEntity {
  const OcrDocumentEntity({required this.pages});

  /// 按用户选择顺序排列的 OCR 页面。
  final List<OcrPageEntity> pages;

  /// 按页汇总的原始 OCR 文本，页面之间保留空行。
  String get plainText => pages.map((page) => page.plainText).join('\n\n');

  /// 文档是否包含至少一行非空 OCR 文字。
  bool get isEmpty => pages.every(
    (page) => page.lines.every((line) => line.text.trim().isEmpty),
  );
}
