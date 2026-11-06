import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';
import 'widgets/auth_page.dart';
import 'auth_session.dart';
import 'otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    required this.phoneNumber,
    required this.onEditPhone,
  });

  final String phoneNumber;
  final VoidCallback onEditPhone;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final body = {
        'phone': widget.phoneNumber,
        'name': _name.text,
        'email': _email.text,
        'password': _password.text,
      };
      Future<Map<String, dynamic>> issue() =>
          authSession.request('auth/register', body: body);
      final challenge = await issue();
      if (!mounted) return;
      final tokens = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: widget.phoneNumber,
            challenge: challenge,
            resend: issue,
            verifyPath: 'auth/register/verify',
          ),
        ),
      );
      if (!mounted || tokens == null) return;
      await authSession.signIn(tokens);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Create your account',
      subtitle: 'Just a few details to get started.',
      phoneNumber: widget.phoneNumber,
      onEditPhone: widget.onEditPhone,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthFieldLabel('Full name'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 18),
            const AuthFieldLabel('Email address (optional)'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                helperText:
                    'Add your email for future account recovery, ride receipts, and important updates. You can verify it later.',
                helperMaxLines: 4,
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 18),
            const AuthFieldLabel('Create a password'),
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                hintText: 'At least 12 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || !validAuthPassword(value)) {
                  return 'Use 12 to 128 bytes';
                }
                return null;
              },
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _busy ? null : _createAccount,
              child: Text(_busy ? 'Please wait…' : 'Send verification code'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Verify your phone to create your account. '
              'Terms and privacy documents will be linked '
              'before production release.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HiGoTheme.secondaryText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
