import 'package:flutter/material.dart';

import 'auth_session.dart';
import 'otp_screen.dart';
import 'widgets/auth_page.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _password = TextEditingController();
  String? _recoveryToken;
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_recoveryToken == null) {
        final body = {'phone': widget.phoneNumber};
        Future<Map<String, dynamic>> issue() =>
            authSession.request('auth/recovery/request', body: body);
        final challenge = await issue();
        if (!mounted) return;
        final proof = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: widget.phoneNumber,
              challenge: challenge,
              resend: issue,
              verifyPath: 'auth/recovery/verify',
            ),
          ),
        );
        if (mounted) _recoveryToken = proof?['recovery_token'] as String?;
      } else {
        if (!validAuthPassword(_password.text)) {
          throw const AuthError('Use a password between 12 and 128 bytes.');
        }
        await authSession.request(
          'auth/recovery/reset',
          body: {'recovery_token': _recoveryToken!, 'password': _password.text},
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      if (error is AuthError && error.status == 400) _recoveryToken = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthPage(
    title: 'Reset your password',
    subtitle: _recoveryToken == null
        ? 'If this phone is registered, HiGO will send a verification code.'
        : 'Enter a new password for your account.',
    phoneNumber: widget.phoneNumber,
    onEditPhone: () => Navigator.of(context).pop(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_recoveryToken != null)
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(
            _busy
                ? 'Please wait…'
                : _recoveryToken == null
                ? 'Send code'
                : 'Reset password',
          ),
        ),
      ],
    ),
  );
}
