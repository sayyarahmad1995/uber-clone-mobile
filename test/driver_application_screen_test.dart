import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uberclone/features/auth/auth_session.dart';
import 'package:uberclone/features/driver/account/driver_application_screen.dart';

const _application = '/api/v1/me/driver-application';

class _Fixture {
  Map<String, dynamic> draft = {};
  String status = 'draft';
  String? reason;
  int identityUploads = 0;
  int vehicleUploads = 0;
  int submissions = 0;
  bool failVehicleOnce = false;
  final payloads = <Map<String, dynamic>>[];

  Future<AuthSession> login() async {
    FlutterSecureStorage.setMockInitialValues({});
    final session = AuthSession(
      base: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access');
        if (request.url.path == _application) {
          if (request.method == 'PATCH') {
            draft = jsonDecode(request.body) as Map<String, dynamic>;
            expect(draft.values, everyElement(isA<String>()));
          } else if (request.method == 'POST') {
            submissions++;
            payloads.add(jsonDecode(request.body) as Map<String, dynamic>);
            status = 'under_review';
            draft.remove('step');
          } else {
            expect(request.method, 'GET');
          }
          return _json({
            'status': status,
            'draft': draft,
            if (reason != null) 'reason': reason,
          });
        }
        if (request.url.path == '/api/v1/me/driver-submission') {
          expect(request.method, 'POST');
          identityUploads++;
          return _json({'version': 4});
        }
        if (request.url.path == '/api/v1/me/vehicles') {
          expect(request.method, 'POST');
          expect(draft['identity_version'], '4');
          vehicleUploads++;
          if (failVehicleOnce) {
            failVehicleOnce = false;
            return _json({'error': 'invalid_document'}, 400);
          }
          return _json({'vehicle_id': 12, 'version': 5});
        }
        return _json({'id': 1, 'name': 'Driver Applicant'});
      }),
    );
    await session.signIn({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    return session;
  }

  http.Response _json(Object data, [int status = 200]) =>
      http.Response(jsonEncode(data), status);
}

void main() {
  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    AuthSession session, {
    Future<Uint8List?> Function(int)? picker,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: DriverApplicationScreen(session: session, pickDocument: picker),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('resumes completed steps and submits the exact saved versions', (
    tester,
  ) async {
    final fixture = _Fixture();
    final session = await fixture.login();
    await open(tester, session);
    expect(find.text('Driver Details'), findsOneWidget);
    await tap(tester, 'Save and continue');
    expect(fixture.draft['legal_name'], 'Driver Applicant');
    expect(fixture.submissions, 0);

    await open(tester, session);
    expect(find.text('Vehicle Details'), findsOneWidget);
    for (final (label, value) in [
      ('Vehicle make', 'Toyota'),
      ('Vehicle model', 'Corolla'),
      ('Manufacturing year', '2022'),
      ('Vehicle color', 'White'),
      ('Registration number', 'ABC-123'),
    ]) {
      await tester.enterText(find.widgetWithText(TextFormField, label), value);
    }
    await tap(tester, 'Save and continue');
    expect(find.text('Upload Documents'), findsOneWidget);

    // Treat both server-acknowledged uploads as already complete after reopen.
    fixture.draft.addAll({
      'step': '3',
      'vehicle_id': '12',
      'identity_version': '4',
      'vehicle_version': '5',
    });
    await open(tester, session);
    expect(find.text('Review & Submit'), findsOneWidget);
    expect(fixture.submissions, 0);
    await tap(tester, 'Submit application');
    expect(fixture.payloads.single, {
      'identity_version': 4,
      'vehicle_id': '12',
      'vehicle_version': 5,
    });
    expect(find.text('Application Under Review'), findsOneWidget);
    await open(tester, session);
    expect(find.text('Application Under Review'), findsOneWidget);
    expect(fixture.submissions, 1);
  });

  testWidgets('shows one outcome and resumes a requested revision', (
    tester,
  ) async {
    final fixture = _Fixture()
      ..status = 'rejected'
      ..reason = 'Upload a clearer CNIC.'
      ..draft = {
        'vehicle_id': '12',
        'identity_version': '4',
        'vehicle_version': '5',
      };
    final session = await fixture.login();
    await open(tester, session);
    expect(find.text('Application Needs Changes'), findsOneWidget);
    expect(find.text('Reason: Upload a clearer CNIC.'), findsOneWidget);
    await tap(tester, 'Revise application');
    expect(fixture.draft['identity_version'], '');
    expect(fixture.draft['vehicle_version'], '');
    expect(fixture.draft['vehicle_id'], '12');
    await open(tester, session);
    expect(find.text('Driver Details'), findsOneWidget);
    expect(fixture.submissions, 0);
  });
  testWidgets('resumes after a partial document upload without repeating it', (
    tester,
  ) async {
    final fixture = _Fixture()
      ..failVehicleOnce = true
      ..draft = {
        'step': '2',
        'legal_name': 'Driver Applicant',
        'make': 'Toyota',
        'model': 'Corolla',
        'manufacture_year': '2022',
        'color': 'White',
        'registration_number': 'ABC-123',
      };
    final session = await fixture.login();
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
    );
    Future<Uint8List?> pick(int _) async => bytes;
    await open(tester, session, picker: pick);

    Future<void> select(String label) async {
      final finder = find.text('Choose $label');
      await tester.ensureVisible(finder);
      await tester.runAsync(() async {
        await tester.tap(finder);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Replace $label'), findsOneWidget);
    }

    for (final label in [
      'CNIC front',
      'CNIC back',
      'Vehicle registration',
      'Vehicle insurance',
    ]) {
      await select(label);
    }
    await tap(tester, 'Save documents and continue');
    expect(fixture.draft['identity_version'], '4');
    expect(fixture.identityUploads, 1);
    expect(fixture.vehicleUploads, 1);
    expect(fixture.submissions, 0);

    await open(tester, session, picker: pick);
    expect(find.text('Upload Documents'), findsOneWidget);
    expect(find.text('Saved'), findsNWidgets(2));
    await select('Vehicle registration');
    await select('Vehicle insurance');
    await tap(tester, 'Save documents and continue');
    expect(find.text('Review & Submit'), findsOneWidget);
    expect(fixture.identityUploads, 1);
    expect(fixture.vehicleUploads, 2);
    expect(fixture.submissions, 0);
  });
}
