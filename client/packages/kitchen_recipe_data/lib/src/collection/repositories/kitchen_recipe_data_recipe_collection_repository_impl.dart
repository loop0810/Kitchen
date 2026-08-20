import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../database/kitchen_recipe_data_app_database.dart';
import '../../recipe/mappers/kitchen_recipe_data_recipe_mapper.dart';

class RecipeCollectionRepositoryImpl implements RecipeCollectionRepository {
  RecipeCollectionRepositoryImpl(
    this._database, {
    Future<Directory> Function()? coverDirectoryProvider,
  }) : _coverDirectoryProvider =
           coverDirectoryProvider ?? _defaultCoverDirectory;

  final AppDatabase _database;
  final Future<Directory> Function() _coverDirectoryProvider;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<RecipeCollectionEntity>> watchCollections() =>
      _database.watchCollectionSummaries().asyncMap(
        (items) => Future.wait(
          items.map(
            (item) async => RecipeMapper.collectionSummaryToDomain(
              item,
              coverBytes: await _readCover(item.collection.coverPath),
            ),
          ),
        ),
      );

  @override
  Future<RecipeCollectionDetailEntity?> getCollectionDetail(
    String collectionId,
  ) async {
    final data = await _database.getCollectionDetail(collectionId);
    return data == null
        ? null
        : RecipeMapper.collectionDetailToDomain(
            data,
            coverBytes: await _readCover(data.summary.collection.coverPath),
          );
  }

  @override
  Future<String> createCollection({
    required String name,
    Uint8List? coverBytes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final coverPath = coverBytes == null ? null : await _writeCover(coverBytes);
    try {
      await _database
          .into(_database.recipeCollections)
          .insert(
            RecipeCollectionsCompanion.insert(
              id: id,
              name: normalizeRecipeCollectionName(name),
              position: await _database.nextCollectionPosition(),
              coverPath: Value(coverPath),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } catch (_) {
      await _deleteCover(coverPath);
      rethrow;
    }
    return id;
  }

  @override
  Future<void> updateCollection({
    required String collectionId,
    required String name,
    required RecipeCollectionCoverChange coverChange,
  }) async {
    final current = await (_database.select(
      _database.recipeCollections,
    )..where((row) => row.id.equals(collectionId))).getSingleOrNull();
    if (current == null) throw StateError('Collection does not exist.');
    final replacementPath =
        coverChange.kind == RecipeCollectionCoverChangeKind.replace
        ? await _writeCover(coverChange.bytes!)
        : null;
    final nextPath = switch (coverChange.kind) {
      RecipeCollectionCoverChangeKind.keep => current.coverPath,
      RecipeCollectionCoverChangeKind.remove => null,
      RecipeCollectionCoverChangeKind.replace => replacementPath,
    };
    late final int count;
    try {
      count =
          await (_database.update(
            _database.recipeCollections,
          )..where((row) => row.id.equals(collectionId))).write(
            RecipeCollectionsCompanion(
              name: Value(normalizeRecipeCollectionName(name)),
              coverPath: Value(nextPath),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } catch (_) {
      await _deleteCover(replacementPath);
      rethrow;
    }
    if (count == 0) {
      await _deleteCover(replacementPath);
      throw StateError('Collection does not exist.');
    }
    if (coverChange.kind != RecipeCollectionCoverChangeKind.keep) {
      await _deleteCover(current.coverPath);
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    final current = await (_database.select(
      _database.recipeCollections,
    )..where((row) => row.id.equals(collectionId))).getSingleOrNull();
    await (_database.delete(
      _database.recipeCollections,
    )..where((row) => row.id.equals(collectionId))).go();
    await _deleteCover(current?.coverPath);
  }

  @override
  Future<Set<String>> getCollectionIdsForRecipe(String recipeId) =>
      _database.collectionIdsForRecipe(recipeId);

  @override
  Future<void> setCollectionsForRecipe({
    required String recipeId,
    required Set<String> collectionIds,
  }) => _database.replaceCollectionsForRecipe(
    recipeId: recipeId,
    collectionIds: collectionIds,
  );

  @override
  Future<void> appendRecipesToCollection({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) => _database.appendRecipesToCollection(
    collectionId: collectionId,
    orderedRecipeIds: orderedRecipeIds,
  );

  @override
  Future<int> removeRecipeFromCollection({
    required String collectionId,
    required String recipeId,
  }) => _database.removeRecipeFromCollection(
    collectionId: collectionId,
    recipeId: recipeId,
  );

  @override
  Future<void> restoreRecipeToCollection({
    required String collectionId,
    required String recipeId,
    required int position,
  }) => _database.restoreRecipeToCollection(
    collectionId: collectionId,
    recipeId: recipeId,
    position: position,
  );

  @override
  Future<void> reorderCollectionMembers({
    required String collectionId,
    required List<String> orderedRecipeIds,
  }) => _database.reorderCollectionMembers(
    collectionId: collectionId,
    orderedRecipeIds: orderedRecipeIds,
  );

  /// 启动时机会式清理没有数据库引用的受控封面。
  Future<void> cleanupOrphanedCovers() async {
    final directory = await _coverDirectoryProvider();
    if (!await directory.exists()) return;
    final referenced =
        (await _database.select(_database.recipeCollections).get())
            .map((row) => row.coverPath)
            .whereType<String>()
            .toSet();
    final staleBefore = DateTime.now().subtract(const Duration(days: 1));
    await for (final entry in directory.list()) {
      if (entry is File && !referenced.contains(p.basename(entry.path))) {
        try {
          // 写文件到数据库提交之间存在短暂窗口，宽限期避免并发机会式清理
          // 删除仍在提交中的新封面。
          if ((await entry.stat()).modified.isAfter(staleBefore)) continue;
          await entry.delete();
        } on FileSystemException catch (error, stackTrace) {
          // 机会式清理失败不影响集合读取，下次启动会再次尝试；只屏蔽文件
          // 系统错误，其余异常仍向上传递以暴露实现缺陷。
          developer.log(
            'orphaned_cover_delete_failed',
            name: 'kitchen_recipe_data',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  Future<String> _writeCover(Uint8List bytes) async {
    if (bytes.isEmpty) throw ArgumentError('Collection cover cannot be empty.');
    final directory = await _coverDirectoryProvider();
    await directory.create(recursive: true);
    final name = '${_uuid.v4()}.jpg';
    await File(p.join(directory.path, name)).writeAsBytes(bytes, flush: true);
    return name;
  }

  Future<Uint8List?> _readCover(String? relativePath) async {
    if (!_isControlledName(relativePath)) return null;
    try {
      final directory = await _coverDirectoryProvider();
      return File(p.join(directory.path, relativePath!)).readAsBytes();
    } on FileSystemException catch (error, stackTrace) {
      // 封面文件丢失或不可读时集合仍需要可读，但不能因此隐藏所有异常；
      // 非文件系统错误交由调用方传递。
      developer.log(
        'collection_cover_read_failed',
        name: 'kitchen_recipe_data',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _deleteCover(String? relativePath) async {
    if (!_isControlledName(relativePath)) return;
    try {
      final directory = await _coverDirectoryProvider();
      final file = File(p.join(directory.path, relativePath!));
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error, stackTrace) {
      // 数据库已经是权威状态；失败文件留给下一次孤立文件清理。
      developer.log(
        'collection_cover_delete_failed',
        name: 'kitchen_recipe_data',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isControlledName(String? value) =>
      value != null && value.isNotEmpty && p.basename(value) == value;

  static Future<Directory> _defaultCoverDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'recipe_collection_covers'));
  }
}
