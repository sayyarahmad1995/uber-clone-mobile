import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uberclone/features/auth/auth_session.dart';
import 'package:uberclone/features/driver/account/driver_identity_screen.dart';
import 'package:uberclone/features/driver/vehicles/my_vehicles_screen.dart';

void main() {
  Future<AuthSession> signedIn() async {
    FlutterSecureStorage.setMockInitialValues({});
    final session = AuthSession(
      base: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access');
        final data = switch (request.url.path) {
          '/api/v1/me/driver-submission' => {
            'status': 'approved',
            'version': 2,
            'legal_name': 'Review Rider',
          },
          '/api/v1/me/vehicles' => {
            'vehicles': [
              {
                'vehicle_id': 7,
                'make': 'Toyota',
                'model': 'Corolla',
                'registration_number': 'ABC-123',
                'status': 'rejected',
                'version': 3,
                'rejection_reason': 'Registration image is unclear.',
              },
            ],
          },
          _ => {'id': 1, 'name': 'Review Rider'},
        };
        return http.Response(jsonEncode(data), 200);
      }),
    );
    await session.signIn({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    return session;
  }

  testWidgets('identity shows approval for the returned version', (
    tester,
  ) async {
    final session = await signedIn();
    await tester.pumpWidget(
      MaterialApp(home: DriverIdentityScreen(session: session)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Identity approved · Version 2'), findsOneWidget);
  });

  testWidgets('vehicle shows rejection and the reviewer reason', (
    tester,
  ) async {
    final session = await signedIn();
    await tester.pumpWidget(
      MaterialApp(home: MyVehiclesScreen(session: session)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Rejected · Version 3'), findsOneWidget);
    expect(
      find.textContaining('Registration image is unclear.'),
      findsOneWidget,
    );
  });
}
