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

const _path = '/api/v1/me/driver-application';
const _image =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC';
const _mandatory = [
  'selfie',
  'cnic_front',
  'cnic_back',
  'license_front',
  'license_back',
  'registration',
  'exterior_front',
  'exterior_rear',
  'exterior_right',
  'exterior_left',
  'interior_front',
  'interior_rear',
];

class _Api {
  final draft = <String, String>{'revision': '0'};
  final documents = <String>{};
  final uploads = <String>[];
  String status = 'draft';
  int submitted = 0;
  int previews = 0;

  void change() => draft['revision'] = '${int.parse(draft['revision']!) + 1}';
  http.Response response(Object value, [int code = 200]) =>
      http.Response(jsonEncode(value), code);

  AuthSession session() => AuthSession(
    base: Uri.parse('https://example.test'),
    client: MockClient((request) async {
      if (request.url.path == '/api/v1/auth/refresh') {
        return response({'access_token': 'access', 'refresh_token': 'refresh'});
      }
      expect(request.headers['Authorization'], 'Bearer access');
      if (request.url.path == '/api/v1/me') {
        return response({
          'id': 1,
          'name': 'Driver Applicant',
          'phone': '+923001234567',
          'email': 'driver@example.test',
          'email_verified': true,
        });
      }
      final data = request.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(request.body) as Map<String, dynamic>;
      final route = '${request.method} ${request.url.path}';
      switch (route) {
        case 'GET $_path':
          break;
        case 'PATCH $_path':
          if (data['revision'] != draft['revision'])
            return response({'error': 'onboarding_conflict'}, 409);
          draft.addAll(data.cast<String, String>());
          change();
        case 'POST $_path/document':
          if (data['draft_revision'] != draft['revision'])
            return response({'error': 'onboarding_conflict'}, 409);
          final kind = data['kind'] as String;
          expect(data['image'], _image);
          documents.add(kind);
          uploads.add(kind);
          change();
        case 'GET $_path/preview':
          expect(documents, contains(request.url.queryParameters['kind']));
          previews++;
          return response({'image': _image});
        case 'DELETE $_path/document':
          expect(request.url.queryParameters, {
            'kind': 'additional',
            'draft_revision': draft['revision'],
          });
          documents.remove('additional');
          change();
        case 'POST $_path':
          if (data['draft_revision'] != draft['revision'])
            return response({'error': 'onboarding_conflict'}, 409);
          expect(data['confirmed'], true);
          expect(documents, containsAll(_mandatory));
          submitted++;
          status = 'pending_review';
          change();
        default:
          fail('Unexpected API request: $route');
      }
      return response({
        'status': status,
        'draft': draft,
        'documents': documents.toList(),
      });
    }),
  );
}

void main() {
  Future<AuthSession> login(_Api api) async {
    FlutterSecureStorage.setMockInitialValues({});
    final session = api.session();
    await session.signIn({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    return session;
  }

  void viewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> click(WidgetTester tester, String label) async {
    final item = find.text(label);
    if (item.evaluate().isEmpty)
      await tester.scrollUntilVisible(
        item,
        180,
        scrollable: find.byType(Scrollable).first,
      );
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    AuthSession session, {
    Future<Uint8List?> Function(int)? capture,
  }) async {
    Future<Uint8List?> pick(int _) async => base64Decode(_image);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: DriverApplicationScreen(
          session: session,
          pickDocument: pick,
          captureSelfie: capture ?? pick,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String label) async {
    final item = find.text(label);
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(item);
      await Future<void>.delayed(const Duration(milliseconds: 75));
    });
    await tester.pumpAndSettle();
  }

  Future<void> date(WidgetTester tester, String label, String value) async {
    final field = find.byKey(ValueKey(label));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      value,
    );
    await click(tester, 'OK');
  }

  Map<String, String> completeDraft(String step) => {
    'step': step,
    'legal_name': 'Driver Applicant',
    'date_of_birth': '1990-01-01',
    'cnic_number': '1234512345671',
    'make': 'Toyota',
    'model': 'Corolla',
    'manufacture_year': '2022',
    'color': 'White',
    'registration_number': 'ABC-123',
    'cnic_validity': 'lifetime',
    'license_expiry': '2050-01-01',
    'registration_validity': 'no_expiry',
  };

  testWidgets('Become a Driver opens the application wizard', (tester) async {
    viewport(tester);
    await tester.pumpWidget(const MaterialApp(home: BecomeDriverScreen()));
    await click(tester, 'Open driver application');
    expect(find.byType(DriverApplicationScreen), findsOneWidget);
  });

  testWidgets(
    'captures and retakes a selfie, validates details and restores an upload',
    (tester) async {
      viewport(tester);
      final api = _Api();
      final session = await login(api);
      var captures = 0;
      await open(
        tester,
        session,
        capture: (limit) async {
          expect(limit, 2 * 1024 * 1024);
          captures++;
          return base64Decode(_image);
        },
      );
      expect(find.text('Driver Details'), findsOneWidget);
      expect(find.text('+923001234567'), findsOneWidget);
      expect(find.text('driver@example.test (verified)'), findsOneWidget);
      await click(tester, 'Next');
      expect(find.text('Driver Details'), findsOneWidget);
      await pick(tester, 'Take selfie');
      await pick(tester, 'Retake selfie');
      expect(captures, 2);
      await date(tester, 'date-date_of_birth', '01/01/1990');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CNIC Number'),
        '1234512345671',
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        '12345-1234567-1',
      );
      await click(tester, 'Next');
      expect(api.uploads, ['selfie']);
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
      await click(tester, 'Next');
      expect(find.text('Upload Documents'), findsOneWidget);
      await pick(tester, 'Choose CNIC Front');
      await click(tester, 'Save CNIC Front');
      expect(api.uploads, ['selfie', 'cnic_front']);
      final restored = api.session();
      await restored.restore();
      await open(tester, restored);
      expect(find.text('Replace CNIC Front'), findsOneWidget);
      expect(find.text('Choose CNIC Back'), findsOneWidget);
      expect(api.previews, 1);
    },
  );

  testWidgets('confirmation gates submission and stale review can refresh', (
    tester,
  ) async {
    viewport(tester);
    final api = _Api();
    api.draft.addAll(completeDraft('3'));
    api.documents.addAll(_mandatory);
    final session = await login(api);
    await open(tester, session);
    expect(find.text('Review & Submit'), findsOneWidget);
    expect(find.text('•••••-••••567-1'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit for Review'),
          )
          .onPressed,
      isNull,
    );
    api.change();
    api.draft['legal_name'] = 'Corrected Applicant';
    const confirmation = 'I confirm the details and documents are accurate.';
    await click(tester, confirmation);
    await click(tester, 'Submit for Review');
    expect(api.submitted, 0);
    // The conflict notice is at the top of the review.
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Refresh application'),
      -240,
      scrollable: scroll,
    );
    await click(tester, 'Refresh application');
    expect(find.text('Corrected Applicant'), findsOneWidget);
    await click(tester, confirmation);
    await click(tester, 'Submit for Review');
    expect(api.submitted, 1);
    expect(find.text('Application Pending Review'), findsOneWidget);
  });

  testWidgets('removes an optional document and keeps other attachments', (
    tester,
  ) async {
    viewport(tester);
    final api = _Api();
    api.draft.addAll(completeDraft('2'));
    api.documents.addAll([..._mandatory, 'additional']);
    await open(tester, await login(api));
    await click(tester, 'Remove additional document');
    expect(api.documents, unorderedEquals(_mandatory));
    expect(find.text('Additional Document Validity'), findsNothing);
  });
}
