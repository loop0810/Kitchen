import 'package:flutter/services.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

class PlatformOcrAdapter implements OcrAdapter {
  const PlatformOcrAdapter();

  // Flutter 只约定“调用哪个原生能力”，不关心 iOS 用 Vision 还是 Android
  // 用 ML Kit。两端都必须返回同一种 Map 结构，下面才能转换成同一个 Domain 对象。
  static const _channel = MethodChannel('kitchen_notes/import_ocr');

  @override
  Future<OcrPageEntity> recognize(ImportMediaReference media) async {
    try {
      // path 指向 App 已经保存好的受控图片。原生层负责读取图片、调用系统 OCR，
      // 再返回图片尺寸和每一行文字的坐标；Flutter 这一层不做像素级图像处理。
      final value = await _channel.invokeMethod<Object?>('recognizeDocument', {
        'path': media.localPath,
        'rotationQuarterTurns': media.rotationQuarterTurns,
      });
      final document = Map<Object?, Object?>.from(value! as Map);
      // 原生返回的坐标已经统一成相对坐标：left/right/top/bottom 都在 0 到 1
      // 之间。这样不同尺寸的图片和不同平台的像素坐标可以使用同一个 Domain 模型。
      final lines = (document['lines']! as List<Object?>)
          .map((value) {
            final line = Map<Object?, Object?>.from(value! as Map);
            return OcrLineEntity(
              id: line['id']! as String,
              text: line['text']! as String,
              confidence: (line['confidence'] as num?)?.toDouble(),
              boundingBox: OcrRectValueObject(
                left: (line['left']! as num).toDouble(),
                top: (line['top']! as num).toDouble(),
                right: (line['right']! as num).toDouble(),
                bottom: (line['bottom']! as num).toDouble(),
              ),
            );
          })
          .toList(growable: false);
      return OcrPageEntity(
        // media.position 是用户选择图片时的顺序，作为这一页在导入文档中的页码。
        pageIndex: media.position,
        pixelWidth: document['width'] as int? ?? 0,
        pixelHeight: document['height'] as int? ?? 0,
        lines: lines,
      );
    } on MissingPluginException {
      throw const ImportPipelineException(
        'ocrUnavailable',
        '当前平台尚未提供离线文字识别，可保留图片后手动整理。',
      );
    } on PlatformException catch (error) {
      throw ImportPipelineException(
        'ocrFailed',
        error.message ?? '图片文字识别失败，可替换图片或稍后重试。',
      );
    }
  }
}
