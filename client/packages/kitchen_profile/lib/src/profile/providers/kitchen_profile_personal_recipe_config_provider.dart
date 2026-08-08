import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';

class ProfileDependencies {
  const ProfileDependencies({
    required this.personalRecipeConfigRepository,
    this.authSessionRepository,
    this.signInWithApple,
    this.clearLocalData,
    this.exportBackup,
    this.restoreBackup,
  });

  final PersonalRecipeConfigRepository personalRecipeConfigRepository;

  /// 账号操作使用正式会话端口；缺省为空时页面仍保持本地优先能力。
  final AuthSessionRepository? authSessionRepository;

  /// iOS Apple 登录入口；认证服务未装配时为空，匿名本地功能仍完整可用。
  final Future<bool> Function()? signInWithApple;

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
