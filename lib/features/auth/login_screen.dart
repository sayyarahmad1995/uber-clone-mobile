import 'package:flutter/material.dart';

import 'auth_session.dart';
import 'recovery_screen.dart';
import 'widgets/auth_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.phoneNumber,
    required this.onEditPhone,
  });

  final String phoneNumber;
  final VoidCallback onEditPhone;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tokens = await authSession.request(
        'auth/login',
        body: {'phone': widget.phoneNumber, 'password': _password.text},
      );
      if (!mounted) return;
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

  Future<void> _recover() async {
    final reset = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecoveryScreen(phoneNumber: widget.phoneNumber),
      ),
    );
    if (mounted && reset == true) {
      _password.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed. Log in to continue.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Welcome back',
      subtitle: 'Sign in to your HiGO account.',
      phoneNumber: widget.phoneNumber,
      onEditPhone: widget.onEditPhone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFieldLabel('Password'),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
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
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _recover,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: _busy ? null : _login,
            child: Text(_busy ? 'Logging in…' : 'Log In'),
          ),
        ],
      ),
    );
  }
}
