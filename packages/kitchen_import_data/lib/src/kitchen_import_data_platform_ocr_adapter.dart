import 'package:flutter/services.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

class PlatformOcrAdapter implements OcrAdapter {
  const PlatformOcrAdapter();

  static const _channel = MethodChannel('kitchen_notes/import_ocr');

  @override
  Future<String> recognize(ImportMediaReference media) async {
    try {
      final text = await _channel.invokeMethod<String>('recognizeText', {
        'path': media.localPath,
        'rotationQuarterTurns': media.rotationQuarterTurns,
      });
      return text?.trim() ?? '';
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
