import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';

void main() {
  test('会话状态支持匿名和认证生命周期', () {
    const anonymous = AuthSessionState.anonymous();
    final authenticated = AuthSessionState.authenticated(
      userId: 'user-1',
      sessionId: 'session-1',
      accessToken: 'short-lived-access',
      accessTokenExpiresAt: DateTime(2026, 8, 8),
    );

    expect(anonymous.status, AuthSessionStatus.anonymous);
    expect(authenticated.status, AuthSessionStatus.authenticated);
    expect(authenticated.userId, 'user-1');
    expect(authenticated.accessToken, isNotEmpty);
  });
}
