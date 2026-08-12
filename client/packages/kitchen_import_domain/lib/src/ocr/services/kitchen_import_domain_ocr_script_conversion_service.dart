import 'package:pinyin/pinyin.dart';

/// 用户主动操作使用的完整繁简转换服务；默认 OCR 流水线不得调用。
class OcrScriptConversionService {
  const OcrScriptConversionService();

  String toSimplified(String value) {
    return ChineseHelper.convertToSimplifiedChinese(value);
  }

  String toTraditional(String value) {
    return ChineseHelper.convertToTraditionalChinese(value);
  }
}
