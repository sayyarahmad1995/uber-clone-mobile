import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/app/app.dart';
import 'package:uberclone/features/driver/account/driver_identity_screen.dart';
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
    await tester.runAsync(() async {
      Navigator.of(shellContext).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              DriverIdentityScreen(pickImage: () async => identityImage),
        ),
      );
    });
    await waitFor(find.text('Choose CNIC front'));
    await tap(find.text('Choose CNIC front'));
    await tap(find.text('Choose CNIC back'));
    await tap(find.text('Submit identity'), network: true, settle: false);
    await waitFor(find.text('Identity submitted · Version 1'));
    await tester.pageBack();
    await tester.pumpAndSettle();

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
      final identity = await restored.driverIdentitySubmission(
        accountId: restored.user?['id'],
      );
      expect(identity['version'], 1);
      expect(identity['status'], 'submitted');
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
