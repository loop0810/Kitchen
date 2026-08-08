import '../entities/kitchen_auth_domain_session_state.dart';
import '../entities/kitchen_auth_domain_verified_identity.dart';

/// 客户端会话边界；Feature 不直接读取令牌或平台安全存储。
abstract interface class AuthSessionRepository {
  /// 观察匿名、认证中、已登录、刷新和失效状态。
  Stream<AuthSessionState> watch();

  /// 异步恢复安全存储中的刷新凭证，不应阻塞本地首屏。
  Future<void> restore();

  /// 使用已验证身份完成首次认证或登录。
  Future<void> authenticate(VerifiedAuthIdentity identity);

  /// 退出当前设备会话。
  Future<void> signOutCurrentDevice();

  /// 撤销当前账号的全部设备会话。
  Future<void> signOutAllDevices();

  /// 发起账号删除；是否清除本机资料由调用方独立确认并执行。
  Future<void> deleteAccount({required bool clearLocalData});

  /// 查询当前账号已绑定的认证身份摘要。
  Future<List<AuthIdentitySummary>> listIdentities();

  /// 请求解绑身份；服务端负责近期认证和最后身份保护。
  Future<void> unbindIdentity(String identityId);
}
