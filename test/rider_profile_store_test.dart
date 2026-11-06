import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uberclone/features/auth/auth_session.dart';
import 'package:uberclone/features/rider/account/rider_profile_store.dart';

void main() {
  late RiderProfileStore store;
  late AuthSession session;
  late Map<String, Object> profile;
  late bool expireAccess;
  late bool rejectUpdate;
  late int updateCalls;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    expireAccess = false;
    rejectUpdate = false;
    updateCalls = 0;
    profile = {
      'id': 8,
      'name': 'Signed-in Rider',
      'email': '',
      'phone': '+923001234567',
      'capabilities': ['rider'],
    };
    session = AuthSession(
      base: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          expect(jsonDecode(request.body), {'refresh_token': 'refresh'});
          return http.Response(
            jsonEncode({'access_token': 'rotated', 'refresh_token': 'next'}),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/logout')) {
          return http.Response('', 204);
        }
        expect(request.url.path, '/api/v1/me');
        if (request.method == 'PATCH') {
          updateCalls++;
          if (expireAccess &&
              request.headers['Authorization'] == 'Bearer access') {
            return http.Response('{"error":"unauthorized"}', 401);
          }
          expect(
            request.headers['Authorization'],
            expireAccess ? 'Bearer rotated' : 'Bearer access',
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.keys, everyElement(isIn(['name', 'email'])));
          if (rejectUpdate) {
            return http.Response('{"error":"invalid_request"}', 400);
          }
          if (body.containsKey('name')) {
            profile['name'] = (body['name'] as String).trim();
          }
          if (body.containsKey('email')) {
            profile['email'] = body['email'] as String;
          }
        } else {
          expect(request.method, 'GET');
        }
        return http.Response(jsonEncode(profile), 200);
      }),
    );
    store = RiderProfileStore(session);
    await session.signIn({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
  });

  test('reads the current account and clears the cache on logout', () async {
    expect(store.profile.firstName, 'Signed-in');
    expect(store.profile.phoneNumber, '+923001234567');
    await session.logout();
    expect(store.profile.fullName, isEmpty);
  });

  test('publishes the accepted server profile after refresh', () async {
    expireAccess = true;
    var notifications = 0;
    store.addListener(() => notifications++);
    await store.updateProfile(fullName: '  Updated Rider  ', email: '');
    expect(updateCalls, 2);
    expect(notifications, 1);
    expect(store.profile.fullName, 'Updated Rider');
    expect(store.profile.email, isEmpty);
    expect(store.profile.phoneNumber, '+923001234567');
  });

  test('keeps the previous profile when the server rejects an edit', () async {
    rejectUpdate = true;
    await expectLater(
      store.updateProfile(fullName: 'Other', email: 'invalid'),
      throwsA(isA<AuthError>()),
    );
    expect(store.profile.fullName, 'Signed-in Rider');
  });
  test('a name-only edit preserves an email changed elsewhere', () async {
    profile['email'] = 'other-device@example.test';
    await store.updateProfile(fullName: 'New Name');
    expect(store.profile.fullName, 'New Name');
    expect(store.profile.email, 'other-device@example.test');
  });
}
