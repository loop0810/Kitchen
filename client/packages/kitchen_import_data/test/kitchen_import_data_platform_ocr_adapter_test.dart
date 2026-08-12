import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/src/ocr/adapters/kitchen_import_data_platform_ocr_adapter.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('kitchen_notes/test_import_ocr');
  const adapter = PlatformOcrAdapter(channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android 元数据映射保留真实零值和实际逐行语言', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'recognizeDocument');
          return {
            'width': 1080,
            'height': 1920,
            'engineIdentifier': 'android-ml-kit-chinese',
            'engineVersion': '16.0.1',
            'modelBundled': true,
            'lines': [
              {
                'id': 'line-0',
                'text': '繁體食材',
                'confidence': 0.0,
                'angleDegrees': 0.0,
                'recognizedLanguage': 'zh-Hant',
                'left': 0.1,
                'top': 0.2,
                'right': 0.8,
                'bottom': 0.3,
              },
            ],
          };
        });

    final page = await adapter.recognize(
      const ImportMediaReference(
        id: 'media',
        localPath: 'image.jpg',
        position: 0,
      ),
    );

    expect(page.lines.single.confidence, 0);
    expect(page.lines.single.angleDegrees, 0);
    expect(page.lines.single.recognizedLanguage, 'zh-Hant');
    expect(page.platformMetadata.engineIdentifier, 'android-ml-kit-chinese');
    expect(page.platformMetadata.modelBundled, isTrue);
  });

  test('iOS Vision 只映射实际返回元数据，不把配置语言写成逐行语言', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return {
            'width': 1000,
            'height': 700,
            'engineIdentifier': 'ios-vision',
            'engineVersion': '3',
            'modelBundled': true,
            'lines': [
              {
                'id': 'line-0',
                'text': '材料',
                'confidence': 0.91,
                'left': 0.2,
                'top': 0.1,
                'right': 0.7,
                'bottom': 0.2,
              },
            ],
          };
        });

    final page = await adapter.recognize(
      const ImportMediaReference(
        id: 'media',
        localPath: 'image.jpg',
        position: 0,
      ),
    );

    expect(page.lines.single.confidence, 0.91);
    expect(page.lines.single.angleDegrees, isNull);
    expect(page.lines.single.recognizedLanguage, isNull);
    expect(page.platformMetadata.engineIdentifier, 'ios-vision');
  });
}
