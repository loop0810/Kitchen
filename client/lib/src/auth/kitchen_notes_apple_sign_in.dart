import 'dart:convert';

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
  KitchenNotesAppleHttpAuthGateway({
    required this._baseUri,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<void> begin({required String flowId, required String nonce}) async {
    final response = await _client.post(
      _baseUri.resolve('/v1/auth/apple/flow'),
      headers: {'content-type': 'application/json', 'idempotency-key': flowId},
      body: jsonEncode({'flowId': flowId, 'nonce': nonce}),
    );
    if (response.statusCode != 204) {
      throw StateError('apple_flow_failed');
    }
  }

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
    final response = await _client.post(
      _baseUri.resolve('/v1/auth/apple/exchange'),
      headers: {'content-type': 'application/json', 'idempotency-key': flowId},
      body: jsonEncode({
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        'nonce': nonce,
        'flowId': flowId,
        ...?email == null ? null : {'email': email},
        ...?givenName == null ? null : {'givenName': givenName},
        ...?familyName == null ? null : {'familyName': familyName},
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body is! Map) {
      throw StateError('apple_exchange_failed');
    }
    final tokens = body['tokens'];
    if (tokens is! Map<String, dynamic>) {
      throw StateError('apple_exchange_invalid_response');
    }
    return AuthSessionTokens(
      userId: tokens['userId'] as String,
      sessionId: tokens['sessionId'] as String,
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      accessTokenExpiresAt: DateTime.parse(tokens['accessExpiresAt'] as String),
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
