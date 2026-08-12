import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:kitchen_import_data/src/ocr/adapters/kitchen_import_data_local_ocr_input_preparer_adapter.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

void main() {
  const preparer = LocalOcrInputPreparerAdapter();
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ocr_preparer_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('0/90/180/270 度物理旋转后尺寸和左上原点证据一致', () async {
    final source = File('${directory.path}/source.png');
    final marker = image.Image(width: 120, height: 80)
      ..clear(image.ColorRgb8(255, 255, 255));
    image.fillRect(
      marker,
      x1: 0,
      y1: 0,
      x2: 29,
      y2: 19,
      color: image.ColorRgb8(240, 10, 10),
    );
    await source.writeAsBytes(image.encodePng(marker));

    for (final turns in [0, 1, 2, 3]) {
      final preparation = await preparer.prepare(
        ImportMediaReference(
          id: 'turn-$turns',
          localPath: source.path,
          position: 0,
          rotationQuarterTurns: turns,
        ),
      );
      final value = image.decodeImage(
        await File(preparation.original.localPath).readAsBytes(),
      )!;
      expect(value.width, turns.isOdd ? 80 : 120);
      expect(value.height, turns.isOdd ? 120 : 80);
      final center = _redCenter(value);
      final normalized = (center.$1 / value.width, center.$2 / value.height);
      switch (turns) {
        case 0:
          expect(normalized.$1, lessThan(0.3));
          expect(normalized.$2, lessThan(0.3));
        case 1:
          expect(normalized.$1, greaterThan(0.7));
          expect(normalized.$2, lessThan(0.3));
        case 2:
          expect(normalized.$1, greaterThan(0.7));
          expect(normalized.$2, greaterThan(0.7));
        case 3:
          expect(normalized.$1, lessThan(0.3));
          expect(normalized.$2, greaterThan(0.7));
      }
      await preparer.release(preparation);
    }
  });

  test('低对比小图只生成一个版本化增强候选且不覆盖原图', () async {
    final source = File('${directory.path}/low-contrast.png');
    final value = image.Image(width: 500, height: 400)
      ..clear(image.ColorRgb8(220, 220, 220));
    image.fillRect(
      value,
      x1: 80,
      y1: 100,
      x2: 420,
      y2: 130,
      color: image.ColorRgb8(205, 205, 205),
    );
    final originalBytes = image.encodePng(value);
    await source.writeAsBytes(originalBytes);

    final preparation = await preparer.prepare(
      ImportMediaReference(
        id: 'low',
        localPath: source.path,
        position: 0,
        contentRevision: 3,
      ),
    );

    expect(preparation.imageQuality.level, ImageQualityLevel.needsAttention);
    expect(
      preparation.imageQuality.issues,
      contains(ImageQualityIssueCode.lowContrast),
    );
    expect(preparation.enhanced, isNotNull);
    expect(preparation.enhanced!.localPath, contains('-r3-enhanced-1.jpg'));
    expect(await source.readAsBytes(), originalBytes);
    expect(await File(preparation.enhanced!.localPath).exists(), isTrue);

    await preparer.release(preparation);
    expect(await source.exists(), isTrue);
    expect(await File(preparation.enhanced!.localPath).exists(), isFalse);
  });

  test('留白较多的正常黑字图片不会被误判为低对比', () async {
    final source = File('${directory.path}/normal-text.png');
    final value = image.Image(width: 900, height: 1500)
      ..clear(image.ColorRgb8(255, 255, 255));
    for (var y = 160; y <= 760; y += 100) {
      image.fillRect(
        value,
        x1: 80,
        y1: y,
        x2: 620,
        y2: y + 28,
        color: image.ColorRgb8(0, 0, 0),
      );
    }
    await source.writeAsBytes(image.encodePng(value));

    final preparation = await preparer.prepare(
      ImportMediaReference(id: 'normal', localPath: source.path, position: 0),
    );

    expect(
      preparation.imageQuality.issues,
      isNot(contains(ImageQualityIssueCode.lowContrast)),
    );
    expect(preparation.enhanced, isNull);
  });

  test('EXIF 方向会在 OCR 前烘焙成实际像素方向', () async {
    final source = File('${directory.path}/exif.jpg');
    final value = image.Image(width: 120, height: 80)
      ..clear(image.ColorRgb8(255, 255, 255));
    value.exif.imageIfd.orientation = 6;
    await source.writeAsBytes([1]);
    final exifPreparer = LocalOcrInputPreparerAdapter(
      decoder: (_) async => value,
    );

    final preparation = await exifPreparer.prepare(
      ImportMediaReference(id: 'exif', localPath: source.path, position: 0),
    );

    expect(preparation.original.source, OcrInputSource.orientationNormalized);
    expect(preparation.original.pixelWidth, 80);
    expect(preparation.original.pixelHeight, 120);
    expect(preparation.original.rotationQuarterTurns, 0);
    expect(await source.exists(), isTrue);
    await exifPreparer.release(preparation);
  });

  test('派生文件写入失败时回退原图且不伪造增强候选', () async {
    final source = File('${directory.path}/fallback.png');
    final value = image.Image(width: 100, height: 100)
      ..clear(image.ColorRgb8(200, 200, 200));
    await source.writeAsBytes(image.encodePng(value));
    final conflictingPath = '${directory.path}/.ocr-conflict-r0-enhanced-1.jpg';
    await Directory(conflictingPath).create();

    final preparation = await preparer.prepare(
      ImportMediaReference(id: 'conflict', localPath: source.path, position: 0),
    );

    expect(preparation.original.localPath, source.path);
    expect(preparation.original.isDerived, isFalse);
    expect(preparation.enhanced, isNull);
  });

  test('内容修订号进入派生文件名，旧候选可独立清理', () async {
    final source = File('${directory.path}/revision.png');
    final value = image.Image(width: 100, height: 100)
      ..clear(image.ColorRgb8(200, 200, 200));
    await source.writeAsBytes(image.encodePng(value));

    final first = await preparer.prepare(
      ImportMediaReference(id: 'revision', localPath: source.path, position: 0),
    );
    final second = await preparer.prepare(
      ImportMediaReference(
        id: 'revision',
        localPath: source.path,
        position: 0,
        contentRevision: 1,
      ),
    );

    expect(first.enhanced!.localPath, isNot(second.enhanced!.localPath));
    await preparer.release(first);
    expect(await File(first.enhanced!.localPath).exists(), isFalse);
    expect(await File(second.enhanced!.localPath).exists(), isTrue);
    await preparer.release(second);
  });
}

(double, double) _redCenter(image.Image value) {
  var count = 0;
  var sumX = 0.0;
  var sumY = 0.0;
  for (final pixel in value) {
    if (pixel.r > 180 && pixel.r > pixel.g * 2 && pixel.r > pixel.b * 2) {
      count += 1;
      sumX += pixel.x;
      sumY += pixel.y;
    }
  }
  expect(count, greaterThan(0));
  return (sumX / count, sumY / count);
}
