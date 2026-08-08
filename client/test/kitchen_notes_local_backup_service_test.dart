import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:kitchen_import_data/kitchen_import_data.dart';
import 'package:kitchen_recipe_data/kitchen_recipe_data.dart';
import 'package:kitchen_notes/src/backup/kitchen_notes_local_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('导出 ZIP 包包含 manifest、摘要和逻辑数据，恢复后仍可读取本地菜谱', () async {
    final directory = await Directory.systemTemp.createTemp('kitchen_backup_');
    addTearDown(() => directory.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => directory.path,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          ),
    );
    final recipeData = RecipeDataModule();
    final importData = ImportDataModule();
    addTearDown(() async {
      await recipeData.close();
      await importData.close();
    });
    final service = KitchenNotesLocalBackupService(
      recipeDataModule: recipeData,
      importDataModule: importData,
    );

    final backup = await service.exportBackup();
    addTearDown(() async {
      if (await backup.exists()) await backup.delete();
    });
    expect(await backup.exists(), isTrue);
    final archive = ZipDecoder().decodeBytes(await backup.readAsBytes());
    expect(archive.findFile('manifest.json'), isNotNull);
    expect(archive.findFile('recipe_data.json'), isNotNull);
    expect(archive.findFile('import_data.json'), isNotNull);

    await service.restoreBackup(backup);
    final snapshot = await recipeData.exportLogicalData();
    expect(snapshot['recipes'], isNotEmpty);
  });

  test('损坏备份在校验失败时不覆盖当前资料', () async {
    final directory = await Directory.systemTemp.createTemp('kitchen_backup_');
    addTearDown(() => directory.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => directory.path,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          ),
    );
    final recipeData = RecipeDataModule();
    final importData = ImportDataModule();
    addTearDown(() async {
      await recipeData.close();
      await importData.close();
    });
    final service = KitchenNotesLocalBackupService(
      recipeDataModule: recipeData,
      importDataModule: importData,
    );
    final before = await recipeData.exportLogicalData();
    final backup = await service.exportBackup();
    addTearDown(() async {
      if (await backup.exists()) await backup.delete();
    });

    final corrupted = File('${backup.path}.corrupted');
    final bytes = await backup.readAsBytes();
    bytes[bytes.length ~/ 2] ^= 0xff;
    await corrupted.writeAsBytes(bytes);
    addTearDown(() async {
      if (await corrupted.exists()) await corrupted.delete();
    });

    await expectLater(service.restoreBackup(corrupted), throwsA(isA<Object>()));
    expect(await recipeData.exportLogicalData(), equals(before));
  });
}
