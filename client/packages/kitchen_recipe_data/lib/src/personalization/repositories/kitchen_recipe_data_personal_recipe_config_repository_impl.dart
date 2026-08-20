import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../../database/kitchen_recipe_data_app_database.dart';

class PersonalRecipeConfigRepositoryImpl
    implements PersonalRecipeConfigRepository {
  PersonalRecipeConfigRepositoryImpl(
    this._database, {
    this.namespace = PersonalRecipeConfigNamespace.anonymous,
    this.remoteGateway,
  });

  final AppDatabase _database;

  /// 此实例绑定的目标命名空间；切换账号时由组合根创建新的实例。
  final PersonalRecipeConfigNamespace namespace;

  /// 账号服务适配口；未配置时缓存仍可完整离线工作，但不会伪报同步成功。
  final PersonalRecipeConfigRemoteGateway? remoteGateway;

  @override
  Stream<PersonalRecipeConfigEntity> watchCached() {
    return (_database.select(_database.personalRecipeConfigCache)
          ..where((row) => row.namespace.equals(namespace.value)))
        .watchSingleOrNull()
        .map(_toDomainOrDefault);
  }

  @override
  Future<PersonalRecipeConfigEntity> getCached() async {
    final row = await (_database.select(
      _database.personalRecipeConfigCache,
    )..where((row) => row.namespace.equals(namespace.value))).getSingleOrNull();
    return _toDomainOrDefault(row);
  }

  @override
  Future<void> save(PersonalRecipeConfigEntity config) async {
    final normalized = _normalize(config).copyWith(syncPending: true);
    await _write(normalized);
    final remote = remoteGateway;
    if (remote == null) return;
    try {
      final confirmed = await remote.update(normalized);
      await _write(
        _normalize(
          confirmed,
        ).copyWith(syncPending: false, lastSyncedAt: DateTime.now()),
      );
    } catch (error, stackTrace) {
      // 缓存已经保存用户修改；保持 pending，启动或网络恢复时继续重试。
      // 降级不得将异常完全吞掉，否则无法区分网络失败与网关实现缺陷。
      developer.log(
        'personal_recipe_config_remote_update_failed',
        name: 'kitchen_recipe_data',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> synchronize() async {
    final remote = remoteGateway;
    if (remote == null) return;
    final cached = await getCached();
    try {
      final synchronized = cached.syncPending
          ? await remote.update(cached)
          : await remote.fetch();
      await _write(
        _normalize(
          synchronized,
        ).copyWith(syncPending: false, lastSyncedAt: DateTime.now()),
      );
    } catch (error, stackTrace) {
      // 启动同步失败不清空缓存；本地创建、导入和编辑继续读取现有值。
      developer.log(
        'personal_recipe_config_synchronize_failed',
        name: 'kitchen_recipe_data',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _write(PersonalRecipeConfigEntity config) {
    return _database
        .into(_database.personalRecipeConfigCache)
        .insertOnConflictUpdate(
          PersonalRecipeConfigCacheCompanion.insert(
            namespace: namespace.value,
            categoriesJson: jsonEncode(config.categories),
            tagsJson: jsonEncode(config.tags),
            difficultiesJson: jsonEncode(config.difficulties),
            serverRevision: Value(config.serverRevision),
            syncPending: Value(config.syncPending),
            lastSyncedAt: Value(config.lastSyncedAt),
            updatedAt: DateTime.now(),
          ),
        );
  }

  PersonalRecipeConfigEntity _toDomainOrDefault(
    PersonalRecipeConfigCacheData? row,
  ) {
    if (row == null) return PersonalRecipeConfigEntity.defaults;
    return PersonalRecipeConfigEntity(
      categories: _decodeList(row.categoriesJson),
      tags: _decodeList(row.tagsJson),
      difficulties: _decodeList(row.difficultiesJson),
      serverRevision: row.serverRevision,
      syncPending: row.syncPending,
      lastSyncedAt: row.lastSyncedAt,
    );
  }

  PersonalRecipeConfigEntity _normalize(PersonalRecipeConfigEntity config) {
    final categories = _normalizeList(config.categories);
    final difficulties = _normalizeList(config.difficulties);
    return PersonalRecipeConfigEntity(
      categories: categories.isEmpty
          ? PersonalRecipeConfigEntity.defaults.categories
          : categories,
      tags: _normalizeList(config.tags),
      difficulties: difficulties.isEmpty
          ? PersonalRecipeConfigEntity.defaults.difficulties
          : difficulties,
      serverRevision: config.serverRevision,
      syncPending: config.syncPending,
      lastSyncedAt: config.lastSyncedAt,
    );
  }

  List<String> _decodeList(String value) {
    return (jsonDecode(value) as List<dynamic>).cast<String>();
  }

  List<String> _normalizeList(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && !result.contains(normalized)) {
        result.add(normalized);
      }
    }
    return List<String>.unmodifiable(result);
  }
}
