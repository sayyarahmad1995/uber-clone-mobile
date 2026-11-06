import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uberclone/features/auth/auth_session.dart';
import 'package:uberclone/features/driver/account/driver_application_screen.dart';
import 'package:uberclone/features/rider/account/become_driver_screen.dart';

const _application = '/api/v1/me/driver-application';

class _ApplicationApi {
  final draft = <String, String>{'revision': '0'};
  final requests = <String>[];
  String status = 'draft';
  bool incomplete = false;

  AuthSession session() => AuthSession(
    base: Uri.parse('https://example.test'),
    client: MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/v1/auth/refresh') {
        return _json({'access_token': 'access', 'refresh_token': 'refresh'});
      }
      expect(request.headers['Authorization'], 'Bearer access');
      if (path == '/api/v1/me') {
        return _json({'id': 1, 'name': 'Driver Applicant'});
      }
      final command = '${request.method} $path';
      requests.add(command);
      final data = request.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(request.body) as Map<String, dynamic>;
      switch (command) {
        case 'GET $_application':
          break;
        case 'PATCH $_application':
          if (draft['revision'] != data['revision']) return _conflict();
          draft.addAll(data.cast<String, String>());
          bumpRevision();
        case 'POST $_application/identity-documents':
          if (draft['revision'] != data['draft_revision']) return _conflict();
          expect(
            data.keys,
            unorderedEquals(['draft_revision', 'cnic_front', 'cnic_back']),
          );
          draft['identity_saved'] = 'true';
          bumpRevision();
        case 'POST $_application/vehicle-documents':
          if (draft['revision'] != data['draft_revision']) return _conflict();
          expect(
            data.keys,
            unorderedEquals([
              'draft_revision',
              'registration_image',
              'insurance_image',
            ]),
          );
          draft['vehicle_saved'] = 'true';
          bumpRevision();
        case 'POST $_application':
          if (draft['revision'] != data['draft_revision']) return _conflict();
          if (incomplete) return _json({'error': 'onboarding_incomplete'}, 409);
          expect(data.keys, ['draft_revision']);
          expect(draft['identity_saved'], 'true');
          expect(draft['vehicle_saved'], 'true');
          status = 'under_review';
          bumpRevision();
        default:
          fail('Unexpected API request: $command');
      }
      return _json({'status': status, 'draft': draft});
    }),
  );

  void bumpRevision() {
    draft['revision'] = (int.parse(draft['revision']!) + 1).toString();
  }

  http.Response _conflict() => _json({'error': 'onboarding_conflict'}, 409);
  http.Response _json(Object data, [int status = 200]) =>
      http.Response(jsonEncode(data), status);
}

void main() {
  Future<AuthSession> login(_ApplicationApi api) async {
    FlutterSecureStorage.setMockInitialValues({});
    final session = api.session();
    await session.signIn({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    return session;
  }

  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, AuthSession session) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
    );
    Future<Uint8List?> pick(int _) async => bytes;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: DriverApplicationScreen(session: session, pickDocument: pick),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String label) async {
    final finder = find.text('Choose $label');
    await tester.ensureVisible(finder);
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Replace $label'), findsOneWidget);
  }

  testWidgets('Become a Driver opens the application wizard', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: BecomeDriverScreen()));
    await tap(tester, 'Open driver application');
    expect(find.byType(DriverApplicationScreen), findsOneWidget);
  });

  testWidgets(
    'resumes a partial draft in a restored session and submits once',
    (tester) async {
      tallScreen(tester);
      final api = _ApplicationApi();
      final session = await login(api);
      await open(tester, session);
      expect(find.text('Driver Details'), findsOneWidget);
      await tap(tester, 'Save and continue');
      expect(api.draft['legal_name'], 'Driver Applicant');

      expect(find.text('Vehicle Details'), findsOneWidget);
      for (final (label, value) in [
        ('Vehicle Make', 'Toyota'),
        ('Vehicle Model', 'Corolla'),
        ('Manufacturing Year', '2022'),
        ('Vehicle Color', 'White'),
        ('Registration Number', 'ABC-123'),
      ]) {
        await tester.enterText(
          find.widgetWithText(TextFormField, label),
          value,
        );
      }
      await tap(tester, 'Save and continue');
      expect(find.text('Upload Documents'), findsOneWidget);
      final continueButton = find.widgetWithText(
        FilledButton,
        'Continue to review',
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await select(tester, 'CNIC front');
      await select(tester, 'CNIC back');
      await tap(tester, 'Save CNIC images');
      expect(api.draft['identity_saved'], 'true');
      expect(api.draft['vehicle_saved'], isNull);
      expect(api.status, 'draft');

      final restored = api.session();
      await restored.restore();
      await open(tester, restored);
      expect(find.text('Upload Documents'), findsOneWidget);
      expect(find.text('Both images saved'), findsOneWidget);
      await select(tester, 'Vehicle registration');
      await select(tester, 'Vehicle insurance');
      await tap(tester, 'Save vehicle images');
      await tap(tester, 'Continue to review');
      expect(find.text('Review & Submit'), findsOneWidget);
      expect(find.text('Registration: ABC-123'), findsOneWidget);
      expect(api.status, 'draft');

      await tap(tester, 'Submit for Review');
      expect(find.text('Application Under Review'), findsOneWidget);
      expect(api.requests.where((entry) => entry.startsWith('POST')), [
        'POST $_application/identity-documents',
        'POST $_application/vehicle-documents',
        'POST $_application',
      ]);
      await open(tester, restored);
      expect(find.text('Application Under Review'), findsOneWidget);
      expect(find.text('Submit for Review'), findsNothing);
    },
  );

  testWidgets('stale confirmation requires refreshing the current draft', (
    tester,
  ) async {
    tallScreen(tester);
    final api = _ApplicationApi();
    api.draft.addAll({
      'step': '3',
      'revision': '4',
      'legal_name': 'Driver Applicant',
      'make': 'Toyota',
      'model': 'Corolla',
      'manufacture_year': '2022',
      'color': 'White',
      'registration_number': 'ABC-123',
      'identity_saved': 'true',
      'vehicle_saved': 'true',
    });
    final session = await login(api);
    await open(tester, session);
    api.bumpRevision();
    api.draft['legal_name'] = 'Corrected Applicant';
    await tap(tester, 'Submit for Review');
    expect(api.status, 'draft');
    await tap(tester, 'Refresh application');
    expect(find.text('Driver: Corrected Applicant'), findsOneWidget);
    api.incomplete = true;
    await tap(tester, 'Submit for Review');
    expect(find.textContaining('save both document pairs'), findsOneWidget);
    expect(find.text('Refresh application'), findsNothing);
    api.incomplete = false;
    await tap(tester, 'Submit for Review');
    expect(find.text('Application Under Review'), findsOneWidget);
  });
}
