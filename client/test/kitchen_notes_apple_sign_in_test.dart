import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kitchen_notes/src/auth/kitchen_notes_apple_sign_in.dart';

void main() {
  test('Apple HTTP gateway提交流程和授权结果但不依赖客户端 userIdentifier', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/flow')) {
        return http.Response('', 204);
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
    final gateway = KitchenNotesAppleHttpAuthGateway(
      baseUri: Uri.parse('https://api.example.test'),
      client: client,
    );

    await gateway.begin(
      flowId: 'flow-1234567890123456',
      nonce: 'nonce-1234567890123456',
    );
    final tokens = await gateway.exchange(
      identityToken: 'identity-token',
      authorizationCode: 'authorization-code',
      nonce: 'nonce-1234567890123456',
      flowId: 'flow-1234567890123456',
      email: 'relay@example.com',
    );

    expect(tokens.userId, 'user-1');
    expect(requests, hasLength(2));
    expect(requests.last.headers['idempotency-key'], 'flow-1234567890123456');
    final requestBody = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(requestBody['identityToken'], 'identity-token');
    expect(requestBody.containsKey('userIdentifier'), isFalse);
  });
}
