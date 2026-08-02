import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_import_data/kitchen_import_data.dart';

void main() {
  test('Android 分享清单保留原始元数据并去重组合文字', () {
    final payload = AndroidSharedImportPayload.fromMap({
      'version': 1,
      'id': 'share-1',
      'action': 'android.intent.action.SEND',
      'mimeType': 'text/plain',
      'title': '照烧鸡腿',
      'subject': '照烧鸡腿',
      'text': '食材：\n鸡腿1个',
      'files': ['/private/share/000.jpg'],
      'createdAtEpochMilliseconds': 1000,
    });

    expect(payload.version, 1);
    expect(payload.mimeType, 'text/plain');
    expect(payload.localPaths, ['/private/share/000.jpg']);
    expect(payload.combinedText, '照烧鸡腿\n食材：\n鸡腿1个');
    expect(payload.createdAt, DateTime.fromMillisecondsSinceEpoch(1000));
  });
}
