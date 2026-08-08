/// 客户端可观察的会话生命周期，不暴露刷新凭证。
enum AuthSessionStatus {
  anonymous,
  authenticating,
  authenticated,
  refreshing,
  invalid,
}

/// 当前账号会话的最小投影，Feature 只依赖该状态而不读取安全存储。
class AuthSessionState {
  const AuthSessionState._({
    required this.status,
    this.userId,
    this.sessionId,
    this.accessToken,
    this.accessTokenExpiresAt,
    this.message,
  });

  /// 未登录状态；本地菜谱核心流程可以继续使用。
  const AuthSessionState.anonymous()
    : this._(status: AuthSessionStatus.anonymous);

  /// 启动恢复或主动认证进行中；不阻塞本地首屏。
  const AuthSessionState.authenticating()
    : this._(status: AuthSessionStatus.authenticating);

  /// 已认证账号的当前会话。
  const AuthSessionState.authenticated({
    required String userId,
    required String sessionId,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) : this._(
         status: AuthSessionStatus.authenticated,
         userId: userId,
         sessionId: sessionId,
         accessToken: accessToken,
         accessTokenExpiresAt: accessTokenExpiresAt,
       );

  /// 刷新访问凭证时保留原账号上下文。
  const AuthSessionState.refreshing({
    required String userId,
    required String sessionId,
    required String accessToken,
    required DateTime accessTokenExpiresAt,
  }) : this._(
         status: AuthSessionStatus.refreshing,
         userId: userId,
         sessionId: sessionId,
         accessToken: accessToken,
         accessTokenExpiresAt: accessTokenExpiresAt,
       );

  /// 会话已失效；本地功能仍保持可用，页面只显示需要重新登录的状态。
  const AuthSessionState.invalid({String? message})
    : this._(status: AuthSessionStatus.invalid, message: message);

  /// 当前生命周期状态。
  final AuthSessionStatus status;

  /// 服务端生成的不透明账号 ID。
  final String? userId;

  /// 当前设备会话 ID。
  final String? sessionId;

  /// 短期访问凭证，仅由会话仓储和 HTTP 适配器使用。
  final String? accessToken;

  /// 访问凭证过期时间。
  final DateTime? accessTokenExpiresAt;

  /// 面向用户的非敏感失效原因。
  final String? message;
}

/// 服务端返回的已绑定认证身份摘要，不包含 provider subject 等敏感标识。
class AuthIdentitySummary {
  const AuthIdentitySummary({
    required this.id,
    required this.provider,
    required this.status,
    this.email,
  });

  /// 服务端生成的身份记录 ID，仅用于解绑操作。
  final String id;

  /// 身份提供方，例如 `apple`。
  final String provider;

  /// 服务端权威状态，例如 `active` 或 `revoked`。
  final String status;

  /// 可选的隐私中继邮箱；不作为账号主键。
  final String? email;
}
