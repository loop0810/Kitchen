import 'package:http/http.dart' as http;
import 'package:kitchen_notes/src/auth/kitchen_notes_auth_session_repository.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 授权结果的可观察结局；取消不是认证错误，也不影响本地功能。
enum KitchenNotesAppleSignInStatus { authenticated, cancelled, failed }

class KitchenNotesAppleSignInResult {
  const KitchenNotesAppleSignInResult(this.status, {this.error});

  final KitchenNotesAppleSignInStatus status;
  final Object? error;
}

/// 将 iOS Apple 授权结果交给服务端网关，不使用客户端 userIdentifier 作为认证依据。
abstract interface class KitchenNotesAppleAuthGateway {
  Future<void> begin({required String flowId, required String nonce});

  Future<AuthSessionTokens> exchange({
    required String identityToken,
    required String authorizationCode,
    required String nonce,
    required String flowId,
    String? email,
    String? givenName,
    String? familyName,
  });
}

/// 认证 exchange 的正式 HTTP 适配器，不把 Apple identity token 写入日志或埋点。
final class KitchenNotesAppleHttpAuthGateway
    implements KitchenNotesAppleAuthGateway {
  KitchenNotesAppleHttpAuthGateway({required Uri baseUri, http.Client? client})
    : _endpoints = KitchenNotesAuthEndpointClient(
        baseUri: baseUri,
        client: client,
      );

  final KitchenNotesAuthEndpointClient _endpoints;

  @override
  Future<void> begin({required String flowId, required String nonce}) =>
      _endpoints.post(
        '/v1/auth/apple/flow',
        idempotencyKey: flowId,
        body: {'flowId': flowId, 'nonce': nonce},
        failureCode: 'apple_flow_failed',
        expectedStatus: 204,
      );

  @override
  Future<AuthSessionTokens> exchange({
    required String identityToken,
    required String authorizationCode,
    required String nonce,
    required String flowId,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    final body = await _endpoints.postJson(
      '/v1/auth/apple/exchange',
      idempotencyKey: flowId,
      body: {
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        'nonce': nonce,
        'flowId': flowId,
        ...?email == null ? null : {'email': email},
        ...?givenName == null ? null : {'givenName': givenName},
        ...?familyName == null ? null : {'familyName': familyName},
      },
      failureCode: 'apple_exchange_failed',
      invalidResponseCode: 'apple_exchange_invalid_response',
    );
    return parseAuthSessionTokens(
      body,
      invalidResponseCode: 'apple_exchange_invalid_response',
    );
  }
}

class KitchenNotesAppleSignInCoordinator {
  KitchenNotesAppleSignInCoordinator({
    required this._gateway,
    required this._sessionRepository,
  });

  final KitchenNotesAppleAuthGateway _gateway;
  final KitchenNotesAuthSessionRepository _sessionRepository;

  Future<KitchenNotesAppleSignInResult> signIn() async {
    final nonce = generateNonce(length: 32);
    final flowId = generateNonce(length: 32);
    try {
      await _gateway.begin(flowId: flowId, nonce: nonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        state: nonce,
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        return const KitchenNotesAppleSignInResult(
          KitchenNotesAppleSignInStatus.failed,
        );
      }
      final tokens = await _gateway.exchange(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        nonce: nonce,
        flowId: flowId,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      await _sessionRepository.acceptVerifiedTokens(tokens);
      return const KitchenNotesAppleSignInResult(
        KitchenNotesAppleSignInStatus.authenticated,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const KitchenNotesAppleSignInResult(
          KitchenNotesAppleSignInStatus.cancelled,
        );
      }
      return KitchenNotesAppleSignInResult(
        KitchenNotesAppleSignInStatus.failed,
        error: error,
      );
    } catch (error) {
      return KitchenNotesAppleSignInResult(
        KitchenNotesAppleSignInStatus.failed,
        error: error,
      );
    }
  }
}
