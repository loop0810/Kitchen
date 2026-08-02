class PersonalRecipeConfigEntity {
  const PersonalRecipeConfigEntity({
    required this.categories,
    required this.tags,
    required this.difficulties,
    this.serverRevision,
    this.syncPending = false,
    this.lastSyncedAt,
  });

  static const defaults = PersonalRecipeConfigEntity(
    categories: ['家常菜', '主食', '汤羹', '烘焙', '甜品', '小吃', '饮品', '酱料与配菜', '其他'],
    tags: ['快手', '下饭'],
    difficulties: ['入门', '简单', '中等', '难'],
  );

  /// 当前账号可选择的主分类，列表顺序即下拉框展示顺序。
  final List<String> categories;

  /// 当前账号可选择的标签，列表顺序即多选入口展示顺序。
  final List<String> tags;

  /// 当前账号可选择的难度，首项是在无法解析难度时使用的默认值。
  final List<String> difficulties;

  /// 服务端配置修订号；尚未成功同步或服务端未提供时为空。
  final String? serverRevision;

  /// 本地是否存在尚未成功上传的修改。
  final bool syncPending;

  /// 最近一次与服务端成功完成双向同步的时间；从未同步时为空。
  final DateTime? lastSyncedAt;

  PersonalRecipeConfigEntity copyWith({
    List<String>? categories,
    List<String>? tags,
    List<String>? difficulties,
    String? serverRevision,
    bool? syncPending,
    DateTime? lastSyncedAt,
  }) {
    return PersonalRecipeConfigEntity(
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      difficulties: difficulties ?? this.difficulties,
      serverRevision: serverRevision ?? this.serverRevision,
      syncPending: syncPending ?? this.syncPending,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
