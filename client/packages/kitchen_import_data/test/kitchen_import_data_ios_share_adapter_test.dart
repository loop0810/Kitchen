import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/kitchen_import_data.dart';

void main() {
  test('iOS 分享清单保留元数据、顺序和去重组合文字', () {
    final payload = IosSharedImportPayload.fromMap({
      'version': 1,
      'id': 'share-ios-1',
      'status': 'ready',
      'mimeType': 'public.jpeg',
      'title': '红烧排骨',
      'subject': '红烧排骨',
      'text': '食材：\n排骨 500g',
      'files': [
        {'path': '/group/share-ios-1/000.jpg'},
        {'path': '/group/share-ios-1/001.jpg'},
      ],
      'createdAtEpochMilliseconds': 1000,
    });

    expect(payload.version, 1);
    expect(payload.id, 'share-ios-1');
    expect(payload.status, 'ready');
    expect(payload.localPaths, [
      '/group/share-ios-1/000.jpg',
      '/group/share-ios-1/001.jpg',
    ]);
    expect(payload.combinedText, '红烧排骨\n食材：\n排骨 500g');
    expect(payload.createdAt, DateTime.fromMillisecondsSinceEpoch(1000));
  });

  test('iOS 分享清单缺少稳定 ID 时拒绝解析', () {
    expect(
      () => IosSharedImportPayload.fromMap({
        'version': 1,
        'createdAtEpochMilliseconds': 1000,
      }),
      throwsFormatException,
    );
  });

  test('iOS 分享路径校验只接受暂存目录内的现有文件', () async {
    final root = await Directory.systemTemp.createTemp('ios-share-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/share-1/000.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    final payload = IosSharedImportPayload.fromMap({
      'version': 1,
      'id': 'share-ios-1',
      'status': 'ready',
      'files': [file.path],
      'createdAtEpochMilliseconds': 1000,
    });

    expect(payload.hasSafePaths(root.path), isTrue);
    final outside = File('${root.parent.path}/outside.jpg')
      ..writeAsBytesSync([4]);
    addTearDown(() => outside.delete());
    final unsafe = IosSharedImportPayload.fromMap({
      'version': 1,
      'id': 'share-ios-2',
      'status': 'ready',
      'files': [outside.path],
      'createdAtEpochMilliseconds': 1000,
    });
    expect(unsafe.hasSafePaths(root.path), isFalse);
  });
}
