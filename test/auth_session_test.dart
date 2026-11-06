import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uberclone/features/auth/auth_session.dart';

void main() {
  test('concurrent logout taps share one revocation', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final started = Completer<void>();
    final response = Completer<http.Response>();
    var calls = 0;
    final session = AuthSession(
      base: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/me':
            return http.Response(jsonEncode({'id': 1}), 200);
          case '/api/v1/auth/logout':
            calls++;
            if (!started.isCompleted) started.complete();
            return response.future;
          default:
            fail('Unexpected request ${request.url.path}');
        }
      }),
    );
    await session.signIn({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });

    final first = session.logout();
    await started.future;
    final second = session.logout();
    await Future<void>.delayed(Duration.zero);
    response.complete(http.Response('', 204));
    await Future.wait([first, second]);

    expect(calls, 1);
    expect(session.authenticated, isFalse);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });
  test('a slow sign-in cannot replace a newer session', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final started = Completer<void>();
    final oldProfile = Completer<http.Response>();
    final session = AuthSession(
      base: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/me');
        if (request.headers['Authorization'] == 'Bearer old') {
          started.complete();
          return oldProfile.future;
        }
        return http.Response(jsonEncode({'id': 2}), 200);
      }),
    );
    final old = session.signIn({
      'access_token': 'old',
      'refresh_token': 'old-refresh',
    });
    await started.future;
    await session.signIn({
      'access_token': 'new',
      'refresh_token': 'new-refresh',
    });
    oldProfile.complete(http.Response(jsonEncode({'id': 1}), 200));
    await old;
    expect(session.user?['id'], 2);
    expect((await const FlutterSecureStorage().readAll()).values, [
      'new-refresh',
    ]);
  });
  test('an old identity draft cannot upload under a new account', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final session = AuthSession(
      base: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/me');
        final id = request.headers['Authorization'] == 'Bearer first' ? 1 : 2;
        return http.Response(jsonEncode({'id': id}), 200);
      }),
    );
    await session.signIn({'access_token': 'first', 'refresh_token': 'one'});
    final owner = session.user?['id'];
    await session.signIn({'access_token': 'second', 'refresh_token': 'two'});
    await expectLater(
      session.submitDriverIdentity({'cnic_front': 'test'}, accountId: owner),
      throwsA(isA<AuthError>()),
    );
    expect(session.user?['id'], 2);
  });
}
