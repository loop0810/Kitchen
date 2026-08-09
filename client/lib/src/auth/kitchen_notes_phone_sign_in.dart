import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:kitchen_notes/src/auth/kitchen_notes_auth_session_repository.dart';

/// 手机号登录流程结果；验证码服务失败时本地菜谱仍保持可用。
enum KitchenNotesPhoneSignInStatus { authenticated, failed }

class KitchenNotesPhoneSignInResult {
  const KitchenNotesPhoneSignInResult(this.status, {this.error});

  final KitchenNotesPhoneSignInStatus status;
  final Object? error;
}

abstract interface class KitchenNotesPhoneAuthGateway {
  Future<String> requestChallenge({
    required String phone,
    required String captchaToken,
    required String installationId,
    required String idempotencyKey,
  });

  Future<AuthSessionTokens> verifyChallenge({
    required String challengeId,
    required String code,
    required String idempotencyKey,
  });
}

/// HTTP 适配器只传验证码和挑战 ID，不保存或记录手机号验证码明文。
final class KitchenNotesPhoneHttpAuthGateway
    implements KitchenNotesPhoneAuthGateway {
  KitchenNotesPhoneHttpAuthGateway({
    required this._baseUri,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<String> requestChallenge({
    required String phone,
    required String captchaToken,
    required String installationId,
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      _baseUri.resolve('/v1/auth/phone/challenge'),
      headers: {
        'content-type': 'application/json',
        'idempotency-key': idempotencyKey,
      },
      body: jsonEncode({
        'phone': phone,
        'captchaToken': captchaToken,
        'installationId': installationId,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('phone_challenge_failed');
    }
    final body = jsonDecode(response.body);
    if (body is! Map || body['challengeId'] is! String) {
      throw StateError('phone_challenge_invalid_response');
    }
    return body['challengeId'] as String;
  }

  @override
  Future<AuthSessionTokens> verifyChallenge({
    required String challengeId,
    required String code,
    required String idempotencyKey,
  }) async {
    final response = await _client.post(
      _baseUri.resolve('/v1/auth/phone/verify'),
      headers: {
        'content-type': 'application/json',
        'idempotency-key': idempotencyKey,
      },
      body: jsonEncode({'challengeId': challengeId, 'code': code}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('phone_verify_failed');
    }
    final body = jsonDecode(response.body);
    final tokens = body is Map ? body['tokens'] : null;
    if (tokens is! Map<String, dynamic>) {
      throw StateError('phone_verify_invalid_response');
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

final class KitchenNotesPhoneSignInCoordinator {
  KitchenNotesPhoneSignInCoordinator({
    required this._gateway,
    required this._sessionRepository,
    required this._installationId,
  });

  final KitchenNotesPhoneAuthGateway _gateway;
  final KitchenNotesAuthSessionRepository _sessionRepository;
  final String _installationId;

  Future<KitchenNotesPhoneSignInResult> signIn({
    required String phone,
    required String captchaToken,
    required String code,
  }) async {
    try {
      final challengeKey = _randomKey();
      final challengeId = await _gateway.requestChallenge(
        phone: phone,
        captchaToken: captchaToken,
        installationId: _installationId,
        idempotencyKey: challengeKey,
      );
      final tokens = await _gateway.verifyChallenge(
        challengeId: challengeId,
        code: code,
        idempotencyKey: _randomKey(),
      );
      await _sessionRepository.acceptVerifiedTokens(tokens);
      return const KitchenNotesPhoneSignInResult(
        KitchenNotesPhoneSignInStatus.authenticated,
      );
    } catch (error) {
      return KitchenNotesPhoneSignInResult(
        KitchenNotesPhoneSignInStatus.failed,
        error: error,
      );
    }
  }
}

String _randomKey() {
  final random = Random.secure();
  return List<int>.generate(
    24,
    (_) => random.nextInt(256),
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
}
