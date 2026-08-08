import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:kitchen_import_data/kitchen_import_data.dart';
import 'package:kitchen_recipe_data/kitchen_recipe_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// 本地备份包首版格式和应用数据的协调入口。
class KitchenNotesLocalBackupService {
  KitchenNotesLocalBackupService({
    required this.recipeDataModule,
    required this.importDataModule,
  });

  final RecipeDataModule recipeDataModule;
  final ImportDataModule importDataModule;
  final _uuid = const Uuid();
  bool _busy = false;

  /// 生成 ZIP 备份包并返回用户可复制或分享的文件路径。
  Future<File> exportBackup() async {
    await _acquire();
    Directory? temporaryDirectory;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final target = File(
        p.join(documents.path, 'kitchen_notes_backup_$timestamp.zip'),
      );
      temporaryDirectory = await Directory(
        p.join(documents.path, '.backup-${_uuid.v4()}'),
      ).create(recursive: true);

      final recipeData = await recipeDataModule.exportLogicalData();
      final importRows = await importDataModule.exportLogicalData();
      final files = <_BackupSourceFile>[];
      final importData = await _prepareImportRows(importRows, files);
      final normalizedRecipeData = await _prepareRecipeData(recipeData, files);
      final entries = <_BackupEntry>[
        await _writeJsonEntry(
          temporaryDirectory,
          'recipe_data.json',
          normalizedRecipeData,
        ),
        await _writeJsonEntry(temporaryDirectory, 'import_data.json', {
          'schemaVersion': 1,
          'tasks': importData,
        }),
      ];
      for (final source in files) {
        final bytes = await File(source.sourcePath).readAsBytes();
        entries.add(
          _BackupEntry(
            source.archiveName,
            bytes,
            bytes.length,
            sha256.convert(bytes).toString(),
          ),
        );
      }

      final manifest = {
        'format': 'kitchen-notes-local-backup',
        'schemaVersion': 1,
        'productVersion': '1.0.0+1',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'content': ['recipes', 'collections', 'imports', 'media'],
        'files': entries
            .map(
              (entry) => {
                'path': entry.path,
                'size': entry.size,
                'sha256': entry.sha256,
              },
            )
            .toList(growable: false),
      };
      final archive = Archive();
      archive.addFile(
        ArchiveFile.string(
          'manifest.json',
          const JsonEncoder.withIndent('  ').convert(manifest),
        ),
      );
      for (final entry in entries) {
        archive.addFile(
          ArchiveFile(entry.path, entry.bytes.length, entry.bytes),
        );
      }
      final encoded = ZipEncoder().encode(archive);
      if (encoded == null) throw StateError('备份包编码失败。');
      await target.writeAsBytes(encoded, flush: true);
      return target;
    } finally {
      if (temporaryDirectory != null && await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
      _busy = false;
    }
  }

  /// 验证并覆盖恢复备份；所有写入前均已完成包、摘要和引用校验。
  Future<void> restoreBackup(File backupFile) async {
    await _acquire();
    Directory? temporaryDirectory;
    try {
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final archiveNames = archive.map((file) => file.name).toList();
      _assertSafeArchiveEntries(archiveNames);
      if (archiveNames.toSet().length != archiveNames.length) {
        throw StateError('备份包含重复文件。');
      }
      final entries = {for (final file in archive) file.name: file};
      final manifest = _readJson(entries, 'manifest.json');
      _validateManifest(manifest, entries);
      final recipeData = _readJson(entries, 'recipe_data.json');
      final importData = _readJson(entries, 'import_data.json');

      temporaryDirectory = await Directory(
        p.join(
          (await getApplicationSupportDirectory()).path,
          'backup_restore',
          _uuid.v4(),
        ),
      ).create(recursive: true);
      final extractedMediaPaths = <String, String>{};
      for (final path in entries.keys.where(
        (value) => value.startsWith('media/'),
      )) {
        final file = entries[path]!;
        final destination = File(p.join(temporaryDirectory.path, path));
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(file.content as List<int>, flush: true);
        extractedMediaPaths[path] = destination.path;
      }
      _validateReferences(recipeData, importData, entries);
      final mediaPaths = await _copyToControlledMedia(extractedMediaPaths);

      // 先保留当前逻辑快照；任一数据库提交失败时恢复旧快照。
      final oldRecipeData = await recipeDataModule.exportLogicalData();
      final oldImportRows = await importDataModule.exportLogicalData();
      try {
        final restoredRecipeData = _resolveRecipeCoverPaths(
          recipeData,
          mediaPaths,
        );
        final restoredImportRows = _resolveImportRows(importData, mediaPaths);
        await recipeDataModule.restoreLogicalData(restoredRecipeData);
        await importDataModule.restoreLogicalData(
          restoredImportRows,
          mediaPaths,
        );
      } catch (_) {
        await recipeDataModule.restoreLogicalData(oldRecipeData);
        await importDataModule.restoreLogicalData(oldImportRows, const {});
        rethrow;
      }
    } finally {
      if (temporaryDirectory != null && await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
      _busy = false;
    }
  }

  Future<void> _acquire() async {
    if (_busy) throw StateError('备份或恢复正在进行中，请稍后重试。');
    _busy = true;
  }

  Future<Map<String, dynamic>> _prepareRecipeData(
    Map<String, dynamic> data,
    List<_BackupSourceFile> files,
  ) async {
    final copy = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final collections = copy['collections'] as List<dynamic>;
    for (final value in collections) {
      final collection = value as Map<String, dynamic>;
      final coverPath = collection['coverPath'] as String?;
      if (coverPath == null) continue;
      final support = await getApplicationSupportDirectory();
      final source = p.join(
        support.path,
        'recipe_collection_covers',
        coverPath,
      );
      files.add(_BackupSourceFile(source, 'media/covers/$coverPath'));
      collection['coverBackupArchiveName'] = 'media/covers/$coverPath';
      collection['coverPath'] = null;
    }
    return copy;
  }

  Future<List<Map<String, dynamic>>> _prepareImportRows(
    List<Map<String, dynamic>> rows,
    List<_BackupSourceFile> files,
  ) async {
    final support = await getApplicationSupportDirectory();
    final mediaRoot = p.normalize(
      p.absolute(p.join(support.path, 'import_media')),
    );
    return rows
        .map((row) {
          final copy = jsonDecode(jsonEncode(row)) as Map<String, dynamic>;
          final media =
              jsonDecode(copy['mediaJson'] as String) as List<dynamic>;
          for (final value in media) {
            final item = value as Map<String, dynamic>;
            final path = item['localPath'] as String;
            _assertControlledSource(path, mediaRoot);
            final archiveName =
                'media/import/${_uuid.v4()}-${p.basename(path)}';
            files.add(_BackupSourceFile(path, archiveName));
            item['backupArchiveName'] = archiveName;
            final originalPath = item['originalLocalPath'] as String?;
            if (originalPath != null && originalPath != path) {
              _assertControlledSource(originalPath, mediaRoot);
              final originalArchiveName =
                  'media/import/${_uuid.v4()}-${p.basename(originalPath)}';
              files.add(_BackupSourceFile(originalPath, originalArchiveName));
              item['backupOriginalArchiveName'] = originalArchiveName;
            }
            item['localPath'] = null;
            item['originalLocalPath'] = null;
          }
          copy['mediaJson'] = jsonEncode(media);
          return copy;
        })
        .toList(growable: false);
  }

  void _assertControlledSource(String sourcePath, String root) {
    final source = p.normalize(p.absolute(sourcePath));
    if (source != root && !p.isWithin(root, source)) {
      throw StateError('导入媒体不在受控媒体目录内。');
    }
  }

  Map<String, dynamic> _resolveRecipeCoverPaths(
    Map<String, dynamic> data,
    Map<String, String> mediaPaths,
  ) {
    final copy = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    for (final value in copy['collections'] as List<dynamic>) {
      final collection = value as Map<String, dynamic>;
      final archiveName = collection['coverBackupArchiveName'] as String?;
      collection['coverPath'] = archiveName == null
          ? null
          : p.basename(mediaPaths[archiveName]!);
    }
    return copy;
  }

  List<Map<String, dynamic>> _resolveImportRows(
    Map<String, dynamic> data,
    Map<String, String> mediaPaths,
  ) => (data['tasks'] as List<dynamic>)
      .map((value) => jsonDecode(jsonEncode(value)) as Map<String, dynamic>)
      .toList(growable: false);

  Future<Map<String, String>> _copyToControlledMedia(
    Map<String, String> extractedPaths,
  ) async {
    final support = await getApplicationSupportDirectory();
    final result = <String, String>{};
    for (final entry in extractedPaths.entries) {
      final relative = entry.key.substring('media/'.length);
      final destination = entry.key.startsWith('media/covers/')
          ? File(
              p.join(
                support.path,
                'recipe_collection_covers',
                p.basename(relative),
              ),
            )
          : File(
              p.join(
                support.path,
                'import_media',
                _uuid.v4(),
                p.basename(relative),
              ),
            );
      await destination.parent.create(recursive: true);
      await File(entry.value).copy(destination.path);
      result[entry.key] = destination.path;
    }
    return result;
  }

  Future<_BackupEntry> _writeJsonEntry(
    Directory directory,
    String path,
    Map<String, dynamic> value,
  ) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(value),
    );
    final file = File(p.join(directory.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return _BackupEntry(
      path,
      bytes,
      bytes.length,
      sha256.convert(bytes).toString(),
    );
  }

  Map<String, dynamic> _readJson(
    Map<String, ArchiveFile> entries,
    String path,
  ) {
    final file = entries[path];
    if (file == null) throw StateError('备份缺少 $path。');
    return jsonDecode(utf8.decode(file.content as List<int>))
        as Map<String, dynamic>;
  }

  void _validateManifest(
    Map<String, dynamic> manifest,
    Map<String, ArchiveFile> entries,
  ) {
    if (manifest['format'] != 'kitchen-notes-local-backup' ||
        manifest['schemaVersion'] != 1) {
      throw StateError('不支持的备份格式。');
    }
    final files = manifest['files'] as List<dynamic>?;
    if (files == null) throw StateError('备份清单损坏。');
    final listedPaths = <String>{};
    for (final value in files) {
      final item = value as Map<String, dynamic>;
      final path = item['path'] as String;
      if (!listedPaths.add(path)) throw StateError('备份清单包含重复文件。');
      final file = entries[path];
      if (file == null) throw StateError('备份缺少文件：$path');
      final content = file.content as List<int>;
      if (content.length != item['size'] ||
          sha256.convert(content).toString() != item['sha256']) {
        throw StateError('备份文件校验失败：$path');
      }
    }
    if (!listedPaths.contains('recipe_data.json') ||
        !listedPaths.contains('import_data.json')) {
      throw StateError('备份清单缺少必要数据文件。');
    }
  }

  void _validateReferences(
    Map<String, dynamic> recipeData,
    Map<String, dynamic> importData,
    Map<String, ArchiveFile> entries,
  ) {
    for (final value in recipeData['collections'] as List<dynamic>) {
      final name =
          (value as Map<String, dynamic>)['coverBackupArchiveName'] as String?;
      if (name != null && !entries.containsKey(name)) {
        throw StateError('集合封面缺失。');
      }
    }
    for (final value in importData['tasks'] as List<dynamic>) {
      final media =
          jsonDecode((value as Map<String, dynamic>)['mediaJson'] as String)
              as List<dynamic>;
      for (final item in media) {
        final name =
            (item as Map<String, dynamic>)['backupArchiveName'] as String?;
        if (name != null && !entries.containsKey(name)) {
          throw StateError('导入媒体缺失。');
        }
        final originalName = (item)['backupOriginalArchiveName'] as String?;
        if (originalName != null && !entries.containsKey(originalName)) {
          throw StateError('导入原始媒体缺失。');
        }
      }
    }
  }

  void _assertSafeArchiveEntries(Iterable<String> names) {
    for (final name in names) {
      if (p.isAbsolute(name) || name.contains('..') || name.contains('\\')) {
        throw StateError('备份包含不安全路径。');
      }
    }
  }
}

class _BackupSourceFile {
  const _BackupSourceFile(this.sourcePath, this.archiveName);
  final String sourcePath;
  final String archiveName;
}

class _BackupEntry {
  const _BackupEntry(this.path, this.bytes, this.size, this.sha256);
  final String path;
  final List<int> bytes;
  final int size;
  final String sha256;
}
