import 'package:flutter/services.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

class PlatformOcrAdapter implements OcrAdapter {
  const PlatformOcrAdapter();

  static const _channel = MethodChannel('kitchen_notes/import_ocr');

  @override
  Future<OcrPageEntity> recognize(ImportMediaReference media) async {
    try {
      final value = await _channel.invokeMethod<Object?>('recognizeDocument', {
        'path': media.localPath,
        'rotationQuarterTurns': media.rotationQuarterTurns,
      });
      final document = Map<Object?, Object?>.from(value! as Map);
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
