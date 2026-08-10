import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/src/ocr/adapters/kitchen_import_data_platform_ocr_adapter.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kitchen_notes/import_ocr');
  const adapter = PlatformOcrAdapter();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('把平台返回的文字行映射为归一化 OCR 页面', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <Object?, Object?>{
        'width': 1200,
        'height': 1600,
        'lines': <Object?>[
          <Object?, Object?>{
            'id': 'line-1',
            'text': '番茄 2 个',
            'confidence': 0.93,
            'left': 0.1,
            'top': 0.2,
            'right': 0.8,
            'bottom': 0.25,
          },
          <Object?, Object?>{
            'id': 'line-2',
            'text': '鸡蛋 3 个',
            'left': 0,
            'top': 0.3,
            'right': 1,
            'bottom': 0.35,
          },
        ],
      };
    });

    final page = await adapter.recognize(_media());

    expect(received?.method, 'recognizeDocument');
    expect(received?.arguments, {
      'path': '/media/000.jpg',
      'rotationQuarterTurns': 3,
    });
    expect(page.pageIndex, 2);
    expect(page.pixelWidth, 1200);
    expect(page.pixelHeight, 1600);
    expect(page.lines.map((line) => line.id), ['line-1', 'line-2']);
    expect(page.lines.first.confidence, 0.93);
    expect(page.lines.first.boundingBox.right, 0.8);
    // 平台未提供置信度时保持为空，结构化阶段才能区分“低置信”和“未知”。
    expect(page.lines.last.confidence, isNull);
  });

  test('平台省略尺寸时回退为 0，避免旧任务无法解析', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return <Object?, Object?>{'lines': <Object?>[]};
    });

    final page = await adapter.recognize(_media());

    expect(page.pixelWidth, 0);
    expect(page.pixelHeight, 0);
    expect(page.lines, isEmpty);
  });

  test('平台未实现 OCR 时抛出可降级的 ocrUnavailable', () async {
    messenger.setMockMethodCallHandler(channel, null);

    await expectLater(
      adapter.recognize(_media()),
      throwsA(
        isA<ImportPipelineException>().having(
          (failure) => failure.code,
          'code',
          'ocrUnavailable',
        ),
      ),
    );
  });

  test('平台识别失败时保留平台提供的错误说明', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ocr_error', message: '图片过暗');
    });

    await expectLater(
      adapter.recognize(_media()),
      throwsA(
        isA<ImportPipelineException>()
            .having((failure) => failure.code, 'code', 'ocrFailed')
            .having((failure) => failure.message, 'message', '图片过暗'),
      ),
    );
  });

  test('平台错误缺少说明时回退到默认中文提示', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ocr_error');
    });

    await expectLater(
      adapter.recognize(_media()),
      throwsA(
        isA<ImportPipelineException>().having(
          (failure) => failure.message,
          'message',
          '图片文字识别失败，可替换图片或稍后重试。',
        ),
      ),
    );
  });
}

ImportMediaReference _media() {
  return const ImportMediaReference(
    id: 'media-1',
    localPath: '/media/000.jpg',
    position: 2,
    rotationQuarterTurns: 3,
  );
}
