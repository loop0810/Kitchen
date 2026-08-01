import 'dart:async';
import 'dart:io';

import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'src/import_task/database/kitchen_import_data_app_database.dart';
import 'src/share/adapters/kitchen_import_data_android_share_adapter.dart';
import 'src/import_task/repositories/kitchen_import_data_import_task_repository_impl.dart';
import 'src/content/adapters/kitchen_import_data_public_content_extractor.dart';
import 'src/ocr/adapters/kitchen_import_data_platform_ocr_adapter.dart';

export 'src/share/adapters/kitchen_import_data_android_share_adapter.dart';

class ImportDataModule {
  ImportDataModule._(this._database)
    : _repository = ImportTaskRepositoryImpl(_database) {
    // 受控媒体清理失败不阻断导入箱启动，后续启动会再次尝试。
    unawaited(_repository.cleanupOrphanedMedia().catchError((_) {}));
  }

  factory ImportDataModule() => ImportDataModule._(ImportAppDatabase());

  final ImportAppDatabase _database;
  final ImportTaskRepositoryImpl _repository;
  final AndroidShareAdapter androidShareAdapter = AndroidShareAdapter();

  ImportTaskRepository get importTaskRepository => _repository;

  PublicContentExtractor get publicContentExtractor =>
      const SafePublicContentExtractor();

  OcrAdapter get ocrAdapter => const PlatformOcrAdapter();

  Future<List<String>> persistPickedImages(List<String> sourcePaths) async {
    final support = await getApplicationSupportDirectory();
    final taskDirectory = Directory(
      p.join(support.path, 'import_media', const Uuid().v4()),
    );
    await taskDirectory.create(recursive: true);
    final persisted = <String>[];
    try {
      for (final (index, sourcePath) in sourcePaths.indexed) {
        final extension = p.extension(sourcePath).toLowerCase();
        final target = p.join(
          taskDirectory.path,
          '${index.toString().padLeft(3, '0')}${extension.isEmpty ? '.jpg' : extension}',
        );
        await File(sourcePath).copy(target);
        persisted.add(target);
      }
      return persisted;
    } catch (_) {
      // 任务尚未创建，失败时只清理由本次选择建立的受控暂存目录。
      if (await taskDirectory.exists()) {
        await taskDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> close() => _database.close();
}
