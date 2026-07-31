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

  /// 从原文识别出的公开 HTTPS 地址；未识别时为空。
  TextColumn get detectedPublicUrl => text().nullable()();

  /// 应用受控媒体引用的 JSON 数组；无图片时为 `[]`。
  TextColumn get mediaJson => text().withDefault(const Constant('[]'))();

  /// 已完成页面汇总后的 OCR 文字；尚未识别时为空。
  TextColumn get ocrText => text().nullable()();

  /// 最新版本化结构草稿 JSON；尚未整理时为空。
  TextColumn get draftJson => text().nullable()();

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
  int get schemaVersion => 1;

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
