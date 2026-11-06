import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/app/app.dart';
import 'package:uberclone/features/driver/account/driver_application_screen.dart';
import 'package:uberclone/features/auth/auth_session.dart';
import 'package:uberclone/features/rider/home/rider_shell.dart';

class _RealHttp extends HttpOverrides {}

void main() {
  const smsLog = String.fromEnvironment('HIGO_TEST_SMS_LOG');
  const phone = '+923001234567';
  const updatedName = 'Updated Test Rider';
  const updatedEmail = 'updated@example.test';
  const oldPassword = 'a strong original password';
  const newPassword = 'a strong replacement password';

  testWidgets('runs authentication and profile editing against Go', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    HttpOverrides.runZoned(
      () => expect(authSession.authenticated, isFalse),
      createHttpClient: _RealHttp().createHttpClient,
    );
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> tap(
      Finder finder, {
      bool network = false,
      bool settle = true,
    }) async {
      await tester.pump();
      await tester.ensureVisible(finder);
      if (network) {
        await tester.runAsync(() async {
          await tester.tap(finder);
          await Future<void>.delayed(const Duration(milliseconds: 600));
        });
      } else {
        await tester.tap(finder);
      }
      if (settle) await tester.pumpAndSettle();
    }

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(finder, findsOneWidget);
      await tester.pumpAndSettle();
    }

    Future<void> enterPhone() async {
      await tester.enterText(find.byType(EditableText), '3001234567');
      await tap(find.text('Continue'));
    }

    Future<void> enterCode() async {
      final code = await tester.runAsync(() async {
        final log = await File(smsLog).readAsString();
        return RegExp(
          'LOCAL SMS ${RegExp.escape(phone)}: ([0-9]{6})',
        ).allMatches(log).last.group(1);
      });
      await tester.enterText(find.byType(EditableText), code!);
      await tap(find.text('Verify & Continue'), network: true);
    }

    Future<void> logout() async {
      await tap(find.text('Account').last);
      final logout = find.text('Log Out');
      await tester.scrollUntilVisible(logout, 120);
      await tap(logout, network: true);
      expect(find.text('Get Started'), findsOneWidget);
    }

    await tester.pumpWidget(const HiGoApp());
    await tester.pumpAndSettle();
    await tap(find.text('Get Started'));
    await enterPhone();
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Test Rider');
    await tester.enterText(fields.at(2), oldPassword);
    await tap(find.text('Send verification code'), network: true);
    await enterCode();
    await waitFor(find.byType(RiderShell));

    await tap(find.text('Account').last);
    await tap(find.text('Personal Information'));
    expect(find.text(phone), findsOneWidget);
    await tap(find.text('Edit Profile'));
    final profileFields = find.byType(EditableText);
    await tester.enterText(profileFields.at(0), updatedName);
    await tester.enterText(profileFields.at(1), updatedEmail);
    await tap(find.text('Save Changes'), network: true);
    await waitFor(find.text(updatedEmail));
    expect(find.text(updatedName), findsWidgets);
    expect(find.text(phone), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
    await tap(find.text('Verify email'));
    await tester.enterText(find.byType(EditableText).at(1), oldPassword);
    await tap(find.text('Send code'), network: true);
    await waitFor(find.text('Code from email'));
    final emailCode = await tester.runAsync(() async {
      final log = await File(smsLog).readAsString();
      return RegExp(
        r'LOCAL EMAIL [^:]+: (em_[A-Za-z0-9_-]+)',
      ).allMatches(log).last.group(1);
    });
    await tester.enterText(find.byType(EditableText).at(2), emailCode!);
    await tap(find.widgetWithText(FilledButton, 'Verify email'), network: true);
    await waitFor(find.text('Verified'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(updatedName), findsOneWidget);

    final identityImage = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
    );
    final shellContext = tester.element(find.byType(RiderShell));
    Future<void> openDriverApplication() async {
      await tester.runAsync(() async {
        Navigator.of(shellContext).push<void>(
          MaterialPageRoute(
            builder: (_) => DriverApplicationScreen(
              pickDocument: (_) async => identityImage,
              captureSelfie: (_) async => identityImage,
            ),
          ),
        );
      });
      await tester.runAsync(() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
    }

    Future<void> reveal(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          180,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
      await tester.pump();
    }

    Future<void> onboardingDate(String label, String value) async {
      final field = find.byKey(ValueKey(label));
      await reveal(field);
      await tap(field);
      await tap(find.byIcon(Icons.edit_outlined));
      await tester.enterText(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextField),
        ),
        value,
      );
      await tap(find.text('OK'));
    }

    Future<void> upload(String label) async {
      final choose = find.text('Choose $label');
      await reveal(choose);
      await tap(choose, network: true, settle: false);
      final save = find.text('Save $label');
      await waitFor(save);
      await reveal(save);
      await tap(save, network: true, settle: false);
      for (
        var attempt = 0;
        attempt < 100 && save.evaluate().isNotEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      expect(save, findsNothing);
      expect(find.text('Preview $label'), findsOneWidget);
    }

    await openDriverApplication();
    await waitFor(find.text('Driver Details'));
    expect(find.text(updatedName), findsWidgets);
    await tap(find.text('Take selfie'), network: true, settle: false);
    await waitFor(find.text('Retake selfie'));
    await onboardingDate('date-date_of_birth', '01/01/1990');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'CNIC Number'),
      '1234512345671',
    );
    await tap(find.text('Next'), network: true, settle: false);
    await waitFor(find.text('Vehicle Details'));
    final vehicleFields = find.byType(EditableText);
    for (final (index, value) in [
      'Toyota',
      'Corolla',
      '2022',
      'Blue',
      'ABC-123',
    ].indexed) {
      await tester.enterText(vehicleFields.at(index), value);
    }
    await tap(find.text('Next'), network: true, settle: false);
    await waitFor(find.text('Upload Documents'));
    await upload('CNIC Front');
    await tap(find.text('Save & exit'), network: true, settle: false);
    await waitFor(find.byType(RiderShell));

    await openDriverApplication();
    await waitFor(find.text('Upload Documents'));
    expect(find.text('Preview CNIC Front'), findsOneWidget);
    await upload('CNIC Back');
    await reveal(find.byKey(const ValueKey('validity-cnic')));
    await tap(find.byKey(const ValueKey('validity-cnic')));
    await tap(find.text('Lifetime').last);
    await upload('Driving License Front');
    await upload('Driving License Back');
    await onboardingDate('date-license_expiry', '01/01/2050');
    await upload('Vehicle Registration');
    await reveal(find.byKey(const ValueKey('validity-registration')));
    await tap(find.byKey(const ValueKey('validity-registration')));
    await tap(find.text('No expiry').last);
    for (final label in [
      'Vehicle Front — Exterior',
      'Vehicle Rear — Exterior',
      'Vehicle Right — Exterior',
      'Vehicle Left — Exterior',
      'Vehicle Front — Interior',
      'Vehicle Rear — Interior',
    ]) {
      await upload(label);
    }
    await tap(find.text('Next'), network: true, settle: false);
    await waitFor(find.text('Review & Submit'));
    await tap(find.text('Save & exit'), network: true, settle: false);
    await waitFor(find.byType(RiderShell));

    // Reopening reloads the saved application, including the selfie preview.
    await openDriverApplication();
    await waitFor(find.text('Review & Submit'));
    expect(find.text('•••••-••••567-1'), findsOneWidget);
    final confirmation = find.text(
      'I confirm the details and documents are accurate.',
    );
    await reveal(confirmation);
    await tap(confirmation);
    await tap(find.text('Submit for Review'), network: true, settle: false);
    await waitFor(find.text('Application Pending Review'));
    await tap(find.text('Back to Account'));

    // A fresh controller restores exclusively from platform storage.
    await tester.runAsync(() async {
      final restored = HttpOverrides.runZoned(
        AuthSession.new,
        createHttpClient: _RealHttp().createHttpClient,
      );
      await restored.restore();
      expect(restored.user?['phone'], phone);
      expect(restored.user?['name'], updatedName);
      expect(restored.user?['email'], updatedEmail);
      expect(restored.user?['email_verified'], isTrue);
      final application = await restored.driverApplication(
        accountId: restored.user?['id'],
      );
      expect(application['status'], 'pending_review');
      final draft = application['draft'] as Map<String, dynamic>;
      expect(draft['registration_number'], 'ABC-123');
      expect(draft['license_expiry'], '2050-01-01');
      expect(application['documents'], hasLength(12));
      await restored.logout();
      await authSession.restore();
    });
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    await tap(find.text('Log In'));
    await enterPhone();
    await tester.enterText(find.byType(EditableText), oldPassword);
    await tap(find.text('Log In'), network: true);
    await waitFor(find.byType(RiderShell));
    await tap(find.text('Account').last);
    await tap(find.text('Personal Information'));
    expect(find.text(updatedEmail), findsOneWidget);
    expect(find.text(updatedName), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await logout();

    // The backend shares a rolling SMS cooldown across registration and recovery.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 61)),
    );
    await tap(find.text('Log In'));
    await enterPhone();
    await tap(find.text('Forgot password?'));
    await tap(find.text('Send code'), network: true);
    await enterCode();
    await tester.enterText(find.byType(EditableText), newPassword);
    await tap(find.text('Reset password'), network: true);
    expect(find.text('Password changed. Log in to continue.'), findsOneWidget);
    expect(find.byType(RiderShell), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), oldPassword);
    await tap(find.text('Log In'), network: true);
    expect(find.text('Invalid phone number or password.'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), newPassword);
    await tap(find.text('Log In'), network: true);
    await waitFor(find.byType(RiderShell));
    await logout();
  }, skip: smsLog.isEmpty);
}
