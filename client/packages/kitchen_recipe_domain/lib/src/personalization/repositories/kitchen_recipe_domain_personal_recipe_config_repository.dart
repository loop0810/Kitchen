import '../entities/kitchen_recipe_domain_personal_recipe_config_entity.dart';

abstract interface class PersonalRecipeConfigRepository {
  /// 持续输出本地缓存；缓存尚未建立时输出内置默认配置。
  Stream<PersonalRecipeConfigEntity> watchCached();

  /// 读取当前缓存快照；缓存尚未建立时返回内置默认配置。
  Future<PersonalRecipeConfigEntity> getCached();

  /// 保存用户修改到缓存并尝试同步；远端失败时保留 pending 状态。
  Future<void> save(PersonalRecipeConfigEntity config);

  /// 应用启动或恢复网络后执行缓存优先的双向同步。
  Future<void> synchronize();
}

abstract interface class PersonalRecipeConfigRemoteGateway {
  /// 拉取当前账号配置；服务端首次调用应返回默认配置。
  Future<PersonalRecipeConfigEntity> fetch();

  /// 幂等更新当前账号配置，并返回服务端确认后的完整快照。
  Future<PersonalRecipeConfigEntity> update(PersonalRecipeConfigEntity config);
}
