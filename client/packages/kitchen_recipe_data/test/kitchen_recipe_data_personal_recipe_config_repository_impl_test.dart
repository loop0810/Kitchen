import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_recipe_data/src/database/kitchen_recipe_data_app_database.dart';
import 'package:kitchen_recipe_data/src/personalization/repositories/kitchen_recipe_data_personal_recipe_config_repository_impl.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('空缓存返回内置默认配置', () async {
    final repository = PersonalRecipeConfigRepositoryImpl(database);

    expect(
      await repository.watchCached().first,
      isA<PersonalRecipeConfigEntity>()
          .having((config) => config.categories.first, '默认分类', '家常菜')
          .having((config) => config.difficulties, '默认难度', [
            '入门',
            '简单',
            '中等',
            '难',
          ]),
    );
  });

  test('远端保存失败时保留本地修改并标记待同步', () async {
    final repository = PersonalRecipeConfigRepositoryImpl(
      database,
      remoteGateway: _FakeRemoteGateway(shouldFail: true),
    );

    await repository.save(
      PersonalRecipeConfigEntity.defaults.copyWith(categories: const ['我的分类']),
    );

    final cached = await repository.getCached();
    expect(cached.categories, ['我的分类']);
    expect(cached.syncPending, isTrue);
  });

  test('启动同步先上传待同步修改并刷新缓存状态', () async {
    final remote = _FakeRemoteGateway();
    final repository = PersonalRecipeConfigRepositoryImpl(
      database,
      remoteGateway: remote,
    );
    await PersonalRecipeConfigRepositoryImpl(database).save(
      PersonalRecipeConfigEntity.defaults.copyWith(categories: const ['离线分类']),
    );

    await repository.synchronize();

    expect(remote.updated?.categories, ['离线分类']);
    final cached = await repository.getCached();
    expect(cached.syncPending, isFalse);
    expect(cached.lastSyncedAt, isNotNull);
  });

  test('无待同步修改时从服务端拉取账号配置', () async {
    final remote = _FakeRemoteGateway(
      fetched: PersonalRecipeConfigEntity.defaults.copyWith(
        tags: const ['低脂', '快手'],
        serverRevision: 'revision-2',
      ),
    );
    final repository = PersonalRecipeConfigRepositoryImpl(
      database,
      remoteGateway: remote,
    );

    await repository.synchronize();

    final cached = await repository.getCached();
    expect(cached.tags, ['低脂', '快手']);
    expect(cached.serverRevision, 'revision-2');
    expect(cached.syncPending, isFalse);
  });

  test('不同命名空间的缓存和 pending 互不读取或上传', () async {
    final accountA = PersonalRecipeConfigRepositoryImpl(
      database,
      namespace: PersonalRecipeConfigNamespace.account('user-a'),
    );
    final accountB = PersonalRecipeConfigRepositoryImpl(
      database,
      namespace: PersonalRecipeConfigNamespace.account('user-b'),
    );

    await accountA.save(
      PersonalRecipeConfigEntity.defaults.copyWith(
        categories: const ['账号 A 分类'],
      ),
    );

    expect((await accountB.getCached()).categories, contains('家常菜'));
    expect((await accountB.getCached()).categories, isNot(contains('账号 A 分类')));
    expect((await accountA.getCached()).syncPending, isTrue);
  });
}

class _FakeRemoteGateway implements PersonalRecipeConfigRemoteGateway {
  _FakeRemoteGateway({
    this.shouldFail = false,
    this.fetched = PersonalRecipeConfigEntity.defaults,
  });

  final bool shouldFail;
  final PersonalRecipeConfigEntity fetched;
  PersonalRecipeConfigEntity? updated;

  @override
  Future<PersonalRecipeConfigEntity> fetch() async {
    if (shouldFail) throw StateError('offline');
    return fetched;
  }

  @override
  Future<PersonalRecipeConfigEntity> update(
    PersonalRecipeConfigEntity config,
  ) async {
    if (shouldFail) throw StateError('offline');
    updated = config;
    return config;
  }
}
