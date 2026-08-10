import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kitchen_auth_domain/kitchen_auth_domain.dart';

/// 平台安全存储端口。生产适配器必须映射到 iOS Keychain / Android Keystore，
/// 不得用 Drift、SharedPreferences 或普通文件实现。
abstract interface class KitchenNotesSecureRefreshTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// 使用系统安全存储保存刷新凭证，不参与 Drift、普通偏好或系统明文备份。
final class FlutterSecureRefreshTokenStore
    implements KitchenNotesSecureRefreshTokenStore {
  FlutterSecureRefreshTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kitchen_notes.auth.refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// 认证网关端口，避免 domain 和页面依赖 HTTP 客户端。
abstract interface class KitchenNotesAuthGateway {
  Future<AuthSessionTokens> authenticate(VerifiedAuthIdentity identity);

  Future<AuthSessionTokens> refresh(String refreshToken);

  Future<void> signOutCurrent(String sessionId, String accessToken);

  Future<void> signOutAll(String accessToken);

  Future<void> deleteAccount(
    String accessToken, {
    required bool clearLocalData,
  });

  Future<List<AuthIdentitySummary>> listIdentities(String accessToken);

  Future<void> unbindIdentity(String accessToken, String identityId);
}

/// 网络会话返回值，只在组合根和 repository 内部携带 refresh token。
class AuthSessionTokens {
  const AuthSessionTokens({
    required this.userId,
    required this.sessionId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
  });

  final String userId;
  final String sessionId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
}

/// 统一管理会话状态并隔离刷新凭证；恢复失败只降级为匿名，不阻塞本地首页。
final class KitchenNotesAuthSessionRepository implements AuthSessionRepository {
  KitchenNotesAuthSessionRepository({
    required this._secureStore,
    required this._gateway,
  });

  final KitchenNotesSecureRefreshTokenStore _secureStore;
  final KitchenNotesAuthGateway _gateway;
  final _controller = StreamController<AuthSessionState>.broadcast();
  AuthSessionState _state = const AuthSessionState.anonymous();
  String? _refreshToken;

  @override
  Stream<AuthSessionState> watch() async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<void> restore() async {
    _set(const AuthSessionState.authenticating());
    _refreshToken = await _secureStore.read();
    if (_refreshToken == null) {
      _set(const AuthSessionState.anonymous());
      return;
    }
    try {
      await _replaceTokens(await _gateway.refresh(_refreshToken!));
    } catch (error) {
      // 仅记录异常类型：认证失败的错误对象可能携带响应体或凭证，不得进入日志。
      developer.log(
        'auth_session_restore_failed:${error.runtimeType}',
        name: 'kitchen_notes',
      );
      await _secureStore.clear();
      _refreshToken = null;
      _set(const AuthSessionState.invalid(message: '登录已失效，请重新登录。'));
    }
  }

  @override
  Future<void> authenticate(VerifiedAuthIdentity identity) async {
    _set(const AuthSessionState.authenticating());
    try {
      await _replaceTokens(await _gateway.authenticate(identity));
    } catch (error) {
      developer.log(
        'auth_session_authenticate_failed:${error.runtimeType}',
        name: 'kitchen_notes',
      );
      _set(const AuthSessionState.invalid(message: '登录服务暂时不可用，本地功能仍可继续使用。'));
      rethrow;
    }
  }

  /// 供 Apple/手机号等已完成服务端验证的适配器提交会话，不接受客户端自填账号字段。
  Future<void> acceptVerifiedTokens(AuthSessionTokens tokens) =>
      _replaceTokens(tokens);

  @override
  Future<void> signOutCurrentDevice() async {
    final current = _state;
    if (current.status != AuthSessionStatus.authenticated ||
        _refreshToken == null) {
      return;
    }
    await _gateway.signOutCurrent(current.sessionId!, current.accessToken!);
    await _clearSession();
  }

  @override
  Future<void> signOutAllDevices() async {
    final current = _state;
    if (current.status != AuthSessionStatus.authenticated) return;
    await _gateway.signOutAll(current.accessToken!);
    await _clearSession();
  }

  @override
  Future<void> deleteAccount({required bool clearLocalData}) async {
    final current = _state;
    if (current.status != AuthSessionStatus.authenticated) return;
    await _gateway.deleteAccount(
      current.accessToken!,
      clearLocalData: clearLocalData,
    );
    await _clearSession();
  }

  @override
  Future<List<AuthIdentitySummary>> listIdentities() async {
    final current = _state;
    if (current.status != AuthSessionStatus.authenticated) return const [];
    return _gateway.listIdentities(current.accessToken!);
  }

  @override
  Future<void> unbindIdentity(String identityId) async {
    final current = _state;
    if (current.status != AuthSessionStatus.authenticated) return;
    await _gateway.unbindIdentity(current.accessToken!, identityId);
  }

  Future<void> _replaceTokens(AuthSessionTokens tokens) async {
    // 先写入安全存储，再发布 authenticated，避免 UI 看到没有可恢复凭证的假状态。
    await _secureStore.write(tokens.refreshToken);
    _refreshToken = tokens.refreshToken;
    _set(
      AuthSessionState.authenticated(
        userId: tokens.userId,
        sessionId: tokens.sessionId,
        accessToken: tokens.accessToken,
        accessTokenExpiresAt: tokens.accessTokenExpiresAt,
      ),
    );
  }

  Future<void> _clearSession() async {
    await _secureStore.clear();
    _refreshToken = null;
    _set(const AuthSessionState.anonymous());
  }

  void _set(AuthSessionState value) {
    _state = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }
}
