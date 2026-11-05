import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/app/app.dart';
import 'package:uberclone/features/auth/auth_session.dart';
import 'package:uberclone/features/rider/home/rider_shell.dart';

class _RealHttp extends HttpOverrides {}

void main() {
  const smsLog = String.fromEnvironment('HIGO_TEST_SMS_LOG');
  const phone = '+923001234567';
  const oldPassword = 'a strong original password';
  const newPassword = 'a strong replacement password';

  testWidgets('runs registration, sessions, and recovery against Go', (
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

    Future<void> tap(Finder finder, {bool network = false}) async {
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
    expect(find.byType(RiderShell), findsOneWidget);

    // A fresh controller restores exclusively from platform storage.
    await tester.runAsync(() async {
      final restored = HttpOverrides.runZoned(
        AuthSession.new,
        createHttpClient: _RealHttp().createHttpClient,
      );
      await restored.restore();
      expect(restored.user?['phone'], phone);
      await restored.logout();
      await authSession.restore();
    });
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    await tap(find.text('Log In'));
    await enterPhone();
    await tester.enterText(find.byType(EditableText), oldPassword);
    await tap(find.text('Log In'), network: true);
    expect(find.byType(RiderShell), findsOneWidget);
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
    expect(find.byType(RiderShell), findsOneWidget);
    await logout();
  }, skip: smsLog.isEmpty);
}
