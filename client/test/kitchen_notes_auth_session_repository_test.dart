import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';
import 'package:kitchen_notes/src/auth/kitchen_notes_auth_session_repository.dart';

void main() {
  test('认证成功后刷新凭证只写入安全存储并发布已登录状态', () async {
    final store = _MemorySecureStore();
    final repository = KitchenNotesAuthSessionRepository(
      secureStore: store,
      gateway: _FakeGateway(),
    );

    await repository.authenticate(
      const VerifiedAuthIdentity(
        provider: 'apple',
        providerSubject: 'subject-1',
        issuerAudienceScope: 'test',
      ),
    );

    expect(store.value, 'refresh-1');
    expect(await repository.watch().first, isA<AuthSessionState>());
  });
}

class _MemorySecureStore implements KitchenNotesSecureRefreshTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}

class _FakeGateway implements KitchenNotesAuthGateway {
  AuthSessionTokens get tokens => AuthSessionTokens(
    userId: 'user-1',
    sessionId: 'session-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime(2026, 8, 8),
  );

  @override
  Future<AuthSessionTokens> authenticate(VerifiedAuthIdentity identity) async =>
      tokens;

  @override
  Future<AuthSessionTokens> refresh(String refreshToken) async => tokens;

  @override
  Future<void> signOutCurrent(String sessionId, String accessToken) async {}

  @override
  Future<void> signOutAll(String accessToken) async {}

  @override
  Future<void> deleteAccount(
    String accessToken, {
    required bool clearLocalData,
  }) async {}

  @override
  Future<List<AuthIdentitySummary>> listIdentities(String accessToken) async =>
      const [];

  @override
  Future<void> unbindIdentity(String accessToken, String identityId) async {}
}
