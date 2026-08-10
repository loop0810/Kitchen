import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kitchen_import_domain/kitchen_import_domain.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'src/import_task/database/kitchen_import_data_app_database.dart';
import 'src/share/adapters/kitchen_import_data_android_share_adapter.dart';
import 'src/share/adapters/kitchen_import_data_ios_share_adapter.dart';
import 'src/import_task/repositories/kitchen_import_data_import_task_repository_impl.dart';
import 'src/content/adapters/kitchen_import_data_public_content_extractor.dart';
import 'src/ocr/adapters/kitchen_import_data_platform_ocr_adapter.dart';

export 'src/share/adapters/kitchen_import_data_android_share_adapter.dart';
export 'src/share/adapters/kitchen_import_data_ios_share_adapter.dart';

class ImportDataModule {
  ImportDataModule._(this._database)
    : _repository = ImportTaskRepositoryImpl(_database) {
    // 受控媒体清理失败不阻断导入箱启动，后续启动会再次尝试；失败原因仍写入
    // 诊断日志，避免受控媒体目录异常长期无声堆积。
    unawaited(
      _repository.cleanupOrphanedMedia().then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) => developer.log(
          'cleanup_orphaned_media_failed',
          name: 'kitchen_import_data',
          error: error,
          stackTrace: stackTrace,
        ),
      ),
    );
  }

  factory ImportDataModule() => ImportDataModule._(ImportAppDatabase());

  final ImportAppDatabase _database;
  final ImportTaskRepositoryImpl _repository;
  final AndroidShareAdapter androidShareAdapter = AndroidShareAdapter();
  final IosShareAdapter iosShareAdapter = IosShareAdapter();

  ImportTaskRepository get importTaskRepository => _repository;

  /// 清除导入任务、草稿和所有受控媒体；媒体删除失败由仓库的机会式清理重试。
  Future<void> clearLocalData() => _repository.deleteAll();

  /// 导出导入任务快照；媒体引用仍由组合根转换为备份包内相对名称。
  Future<List<Map<String, dynamic>>> exportLogicalData() =>
      _database.exportLogicalData();

  /// 用已验证快照恢复导入任务和媒体引用。
  Future<void> restoreLogicalData(
    List<Map<String, dynamic>> rows,
    Map<String, String> mediaPathByArchiveName,
  ) => _database.restoreLogicalData(rows, mediaPathByArchiveName);

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
