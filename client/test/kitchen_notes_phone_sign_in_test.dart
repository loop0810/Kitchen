import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kitchen_notes/src/auth/kitchen_notes_phone_sign_in.dart';

void main() {
  test('模拟手机号 gateway 使用 challenge 和固定验证码走正常 token 响应', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/challenge')) {
        return http.Response(
          jsonEncode({'challengeId': 'challenge-1234567890123456'}),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'tokens': {
            'userId': 'user-1',
            'sessionId': 'session-1',
            'accessToken': 'access-1',
            'refreshToken': 'refresh-1',
            'accessExpiresAt': '2026-08-09T00:00:00Z',
          },
        }),
        200,
      );
    });
    final gateway = KitchenNotesPhoneHttpAuthGateway(
      baseUri: Uri.parse('https://api.example.test'),
      client: client,
    );

    final challenge = await gateway.requestChallenge(
      phone: '13800138000',
      captchaToken: 'local-captcha-ok',
      installationId: 'install-123456',
      idempotencyKey: 'challenge-key-123456',
    );
    final tokens = await gateway.verifyChallenge(
      challengeId: challenge,
      code: '111111',
      idempotencyKey: 'verify-key-123456',
    );

    expect(tokens.userId, 'user-1');
    expect(requests, hasLength(2));
    final verifyBody = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(verifyBody, {
      'challengeId': 'challenge-1234567890123456',
      'code': '111111',
    });
  });
}
