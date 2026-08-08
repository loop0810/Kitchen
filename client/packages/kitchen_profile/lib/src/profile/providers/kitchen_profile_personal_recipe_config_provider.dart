import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

class ProfileDependencies {
  const ProfileDependencies({
    required this.personalRecipeConfigRepository,
    this.clearLocalData,
    this.exportBackup,
    this.restoreBackup,
  });

  final PersonalRecipeConfigRepository personalRecipeConfigRepository;

  /// 清除设备资料库的组合根回调；账号删除由未来会话流程单独确认后调用。
  final Future<void> Function()? clearLocalData;

  /// 生成本机备份并返回用户可分享的文件路径。
  final Future<String> Function()? exportBackup;

  /// 从用户提供的本机路径执行覆盖恢复。
  final Future<void> Function(String path)? restoreBackup;
}

final profileDependenciesProvider = Provider<ProfileDependencies>((ref) {
  throw StateError('请在应用组合根注入 ProfileDependencies。');
});

final personalRecipeConfigProvider = StreamProvider<PersonalRecipeConfigEntity>(
  (ref) {
    return ref
        .watch(profileDependenciesProvider)
        .personalRecipeConfigRepository
        .watchCached();
  },
);
