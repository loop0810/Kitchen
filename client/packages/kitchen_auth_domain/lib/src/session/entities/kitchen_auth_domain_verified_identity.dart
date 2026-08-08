/// 第三方适配器验证后交给认证仓储的身份输入。
class VerifiedAuthIdentity {
  const VerifiedAuthIdentity({
    required this.provider,
    required this.providerSubject,
    required this.issuerAudienceScope,
  });

  /// 登录提供方标识，例如 apple、phone 或 wechat。
  final String provider;

  /// 提供方返回且已完成签名/凭证验证的 subject。
  final String providerSubject;

  /// 生产、测试和不同 audience 的隔离范围。
  final String issuerAudienceScope;
}
