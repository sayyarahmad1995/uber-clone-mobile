import 'package:flutter/material.dart';

import '../../auth/auth_session.dart';
import 'rider_profile_store.dart';

class EmailVerificationDialog extends StatefulWidget {
  const EmailVerificationDialog({super.key, required this.profile});
  final RiderProfile profile;

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  late final _email = TextEditingController(
    text: widget.profile.pendingEmail.isEmpty
        ? widget.profile.email
        : widget.profile.pendingEmail,
  );
  final _password = TextEditingController();
  final _code = TextEditingController();
  late bool _codeAvailable = widget.profile.pendingEmail.isNotEmpty;
  bool _busy = false;
  String? _message;

  Future<void> _run({required bool verify}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (verify) {
        await authSession.verifyEmail(_code.text);
        if (mounted) Navigator.of(context).pop();
      } else {
        await authSession.requestEmailVerification(_email.text, _password.text);
        if (!mounted) return;
        _password.clear();
        _code.clear();
        setState(() {
          _codeAvailable = true;
          _message = 'Code sent. Wait at least 60 seconds before resending.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Email verification'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.profile.emailVerified)
              const Text(
                'Your verified email stays active until you confirm the replacement.',
              ),
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _run(verify: false),
              child: Text(_codeAvailable ? 'Send a new code' : 'Send code'),
            ),
            if (_codeAvailable)
              TextField(
                controller: _code,
                enabled: !_busy,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Code from email'),
              ),
            if (_message != null) Text(_message!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (_codeAvailable)
          FilledButton(
            onPressed: _busy ? null : () => _run(verify: true),
            child: const Text('Verify email'),
          ),
      ],
    ),
  );
}
