import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uberclone/app/app_mode_controller.dart';
import 'package:uberclone/features/auth/auth_session.dart';

void main() {
  test(
    'mode switching uses restored membership and retains the session',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      var driver = false;
      var calls = 0;
      final session = AuthSession(
        base: Uri.parse('https://example.test'),
        client: MockClient((request) async {
          calls++;
          if (request.url.path.endsWith('/logout')) {
            return http.Response('', 204);
          }
          if (request.url.path.endsWith('/refresh')) {
            return http.Response(
              '{"access_token":"new","refresh_token":"next"}',
              200,
            );
          }
          expect(request.url.path, '/api/v1/me');
          return http.Response(
            jsonEncode({
              'id': 7,
              'capabilities': ['rider', if (driver) 'driver'],
            }),
            200,
          );
        }),
      );
      final mode = AppModeController(session);
      await session.signIn({
        'access_token': 'access',
        'refresh_token': 'refresh',
      });
      mode.switchToDriver();
      expect(mode.value, HiGoAppMode.rider);

      driver = true;
      final restored = AuthSession(
        base: Uri.parse('https://example.test'),
        client: MockClient((request) async {
          calls++;
          if (request.url.path.endsWith('/refresh')) {
            expect(jsonDecode(request.body), {'refresh_token': 'refresh'});
            return http.Response(
              '{"access_token":"new","refresh_token":"next"}',
              200,
            );
          }
          if (request.url.path.endsWith('/logout')) {
            return http.Response('', 204);
          }
          return http.Response(
            '{"id":7,"capabilities":["rider","driver"]}',
            200,
          );
        }),
      );
      final restoredMode = AppModeController(restored);
      await restored.restore();
      final beforeSwitch = calls;
      restoredMode.switchToDriver();
      expect(restoredMode.value, HiGoAppMode.driver);
      restoredMode.switchToRider();
      expect(restoredMode.value, HiGoAppMode.rider);
      expect(restored.authenticated, isTrue);
      expect(calls, beforeSwitch);
      restoredMode.switchToDriver();
      await restored.logout();
      expect(restoredMode.value, HiGoAppMode.rider);
      mode.dispose();
      restoredMode.dispose();
    },
  );
}
