import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'kitchen_import_data_app_database.g.dart';

/// 可恢复导入任务表。
///
/// 原始输入、处理中间结果和结构化草稿分列保存，任一处理阶段失败都不会覆盖原文。
class ImportTasks extends Table {
  /// 导入任务稳定 UUID。
  TextColumn get id => text()();

  /// 输入类型的稳定枚举字符串。
  TextColumn get inputKind => text()();

  /// 当前业务状态的稳定枚举字符串。
  TextColumn get status => text()();

  /// 用户粘贴或分享的完整原始文字；无文字时为空字符串。
  TextColumn get originalText => text().withDefault(const Constant(''))();

  /// iOS 或 Android 系统分享的稳定 ID；手动创建的任务为空。
  TextColumn get sourceShareId => text().nullable()();

  /// 从原文识别出的公开 HTTPS 地址；未识别时为空。
  TextColumn get detectedPublicUrl => text().nullable()();

  /// 应用受控媒体引用的 JSON 数组；无图片时为 `[]`。
  TextColumn get mediaJson => text().withDefault(const Constant('[]'))();

  /// 按当前页面顺序汇总的机器 OCR 文字；尚未识别时为空。
  TextColumn get ocrText => text().nullable()();

  /// 用户校对后的 OCR 正文；未校对时为空。
  TextColumn get correctedOcrText => text().nullable()();

  /// 用户在识别文字之外增加的补充说明。
  TextColumn get supplementalText => text().withDefault(const Constant(''))();

  /// 任务内容变化的单调递增代次，过期处理结果不得回写。
  IntColumn get processingGeneration =>
      integer().withDefault(const Constant(0))();

  /// 最新版本化结构草稿 JSON；尚未整理时为空。
  TextColumn get draftJson => text().nullable()();

  /// OCR 文字质量、建议状态和校对修订的版本化 JSON。
  TextColumn get ocrQualityJson => text().withDefault(const Constant('{}'))();

  /// 稳定错误分类；非失败状态为空。
  TextColumn get errorCode => text().nullable()();

  /// 面向用户的错误说明；非失败状态为空。
  TextColumn get errorMessage => text().nullable()();

  /// 保存成功后的正式菜谱 ID；未保存时为空。
  TextColumn get finalRecipeId => text().nullable()();

  /// 任务首次持久化时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 任务内容或状态最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [ImportTasks])
class ImportAppDatabase extends _$ImportAppDatabase {
  ImportAppDatabase() : super(_openConnection());

  ImportAppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // 新增列都提供旧任务可安全恢复的默认值，不重建表，
        // 以免丢失原始文本、媒体引用和已生成的草稿。
        await migrator.addColumn(importTasks, importTasks.correctedOcrText);
        await migrator.addColumn(importTasks, importTasks.supplementalText);
        await migrator.addColumn(importTasks, importTasks.processingGeneration);
      }
      if (from < 3) {
        // 外部分享 ID 只用于重复接管幂等，不改变旧任务的本地内容语义。
        await migrator.addColumn(importTasks, importTasks.sourceShareId);
      }
      if (from < 4) {
        // 质量数据独立于草稿保存，旧任务读取空对象后按 unknown 兼容。
        await migrator.addColumn(importTasks, importTasks.ocrQualityJson);
      }
    },
  );

  Stream<List<ImportTask>> watchImportTasks() {
    return (select(
      importTasks,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch();
  }

  Future<ImportTask?> getImportTask(String taskId) {
    return (select(
      importTasks,
    )..where((row) => row.id.equals(taskId))).getSingleOrNull();
  }

  Future<void> deleteImportTask(String taskId) {
    return (delete(importTasks)..where((row) => row.id.equals(taskId))).go();
  }

  Future<List<Map<String, dynamic>>> exportLogicalData() async {
    final rows = await select(importTasks).get();
    return rows
        .map(
          (row) => {
            'id': row.id,
            'inputKind': row.inputKind,
            'status': row.status,
            'originalText': row.originalText,
            'sourceShareId': row.sourceShareId,
            'detectedPublicUrl': row.detectedPublicUrl,
            'mediaJson': row.mediaJson,
            'ocrText': row.ocrText,
            'correctedOcrText': row.correctedOcrText,
            'supplementalText': row.supplementalText,
            'processingGeneration': row.processingGeneration,
            'draftJson': row.draftJson,
            'ocrQualityJson': row.ocrQualityJson,
            'errorCode': row.errorCode,
            'errorMessage': row.errorMessage,
            'finalRecipeId': row.finalRecipeId,
            'createdAt': row.createdAt.toIso8601String(),
            'updatedAt': row.updatedAt.toIso8601String(),
          },
        )
        .toList(growable: false);
  }

  Future<void> restoreLogicalData(
    List<Map<String, dynamic>> rows,
    Map<String, String> mediaPathByArchiveName,
  ) async {
    await transaction(() async {
      await delete(importTasks).go();
      for (final row in rows) {
        final mediaJson = _restoreMediaPaths(
          row['mediaJson'] as String,
          mediaPathByArchiveName,
        );
        await into(importTasks).insert(
          ImportTasksCompanion.insert(
            id: row['id'] as String,
            inputKind: row['inputKind'] as String,
            status: row['status'] as String,
            originalText: Value(row['originalText'] as String),
            sourceShareId: Value(row['sourceShareId'] as String?),
            detectedPublicUrl: Value(row['detectedPublicUrl'] as String?),
            mediaJson: Value(mediaJson),
            ocrText: Value(row['ocrText'] as String?),
            correctedOcrText: Value(row['correctedOcrText'] as String?),
            supplementalText: Value(row['supplementalText'] as String),
            processingGeneration: Value(row['processingGeneration'] as int),
            draftJson: Value(row['draftJson'] as String?),
            ocrQualityJson: Value(row['ocrQualityJson'] as String? ?? '{}'),
            errorCode: Value(row['errorCode'] as String?),
            errorMessage: Value(row['errorMessage'] as String?),
            finalRecipeId: Value(row['finalRecipeId'] as String?),
            createdAt: DateTime.parse(row['createdAt'] as String),
            updatedAt: DateTime.parse(row['updatedAt'] as String),
          ),
        );
      }
    });
  }

  String _restoreMediaPaths(
    String mediaJson,
    Map<String, String> mediaPathByArchiveName,
  ) {
    final media = jsonDecode(mediaJson) as List<dynamic>;
    for (final value in media) {
      final item = value as Map<String, dynamic>;
      final archiveName = item['backupArchiveName'] as String?;
      if (archiveName != null) {
        final restored = mediaPathByArchiveName[archiveName];
        if (restored == null) throw StateError('备份缺少媒体文件：$archiveName');
        item['localPath'] = restored;
        final originalArchiveName =
            item['backupOriginalArchiveName'] as String?;
        item['originalLocalPath'] = originalArchiveName == null
            ? restored
            : mediaPathByArchiveName[originalArchiveName];
        if (item['originalLocalPath'] == null) {
          throw StateError('备份缺少原始媒体文件：$originalArchiveName');
        }
        item.remove('backupOriginalArchiveName');
      }
      item.remove('backupArchiveName');
    }
    return jsonEncode(media);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final file = File(
      p.join(supportDirectory.path, 'kitchen_notes_import.sqlite'),
    );
    return NativeDatabase.createInBackground(file);
  });
}
