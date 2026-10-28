import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

enum MockAccountType { existing, newUser }

class AccountCheckingScreen extends StatefulWidget {
  const AccountCheckingScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<AccountCheckingScreen> createState() => _AccountCheckingScreenState();
}

class _AccountCheckingScreenState extends State<AccountCheckingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  Timer? _timer;
  bool _checking = true;

  MockAccountType _mockAccountType = MockAccountType.existing;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Simulate an asynchronous account lookup.
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _checking = false;
      });

      _animationController.stop();
    });
  }

  void _continue() {
    final navigator = Navigator.of(context);

    // Pop back to the account checking screen's
    // previous route when editing the phone.
    // In our current flow, we have to pop:
    // Login/Registration -> Checking -> OTP -> Phone.
    void editPhone() {
      navigator.popUntil((route) => route.settings.name == '/phone');
    }

    final Widget destination;

    if (_mockAccountType == MockAccountType.existing) {
      destination = LoginScreen(
        phoneNumber: widget.phoneNumber,
        onEditPhone: editPhone,
      );
    } else {
      destination = RegistrationScreen(
        phoneNumber: widget.phoneNumber,
        onEditPhone: editPhone,
      );
    }

    navigator.push(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background-only gradients.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0.0, 0.35, 0.72, 1.0],
                    colors: [
                      Color(0xFFEEF4FF),
                      Colors.white,
                      Colors.white,
                      Color(0xFFF4E9FF),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: HiGoTheme.navy,
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return SizedBox(
                                width: 160,
                                height: 160,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 142,
                                      height: 142,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: HiGoTheme.primary.withValues(
                                            alpha: 0.10,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                      width: 142,
                                      height: 142,
                                      child: CircularProgressIndicator(
                                        value: _checking ? null : 1,
                                        strokeWidth: 2,
                                        strokeCap: StrokeCap.round,
                                        color: HiGoTheme.primary,
                                        backgroundColor: HiGoTheme.primary
                                            .withValues(alpha: 0.07),
                                      ),
                                    ),

                                    Container(
                                      width: 105,
                                      height: 105,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0EDFF),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: HiGoTheme.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 24,
                                            spreadRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _checking
                                            ? Icons.phonelink_lock_outlined
                                            : Icons.verified_user_outlined,
                                        color: HiGoTheme.primary,
                                        size: 50,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 35),

                          Text(
                            _checking
                                ? 'Checking your account...'
                                : 'Account check complete',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: HiGoTheme.navy,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _checking
                                ? 'Please wait while we check\n'
                                      'your account information.'
                                : 'Choose a mock account type\n'
                                      'to preview the next screen.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),

                          const SizedBox(height: 42),

                          if (_checking)
                            SizedBox(
                              width: 145,
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(8),
                                backgroundColor: const Color(0xFFE2E5F0),
                                color: HiGoTheme.primary,
                              ),
                            ),

                          if (!_checking) ...[
                            const Text(
                              'UI PREVIEW MODE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                                color: HiGoTheme.secondaryText,
                              ),
                            ),

                            const SizedBox(height: 16),

                            SegmentedButton<MockAccountType>(
                              segments: const [
                                ButtonSegment(
                                  value: MockAccountType.existing,
                                  label: Text('Existing'),
                                ),
                                ButtonSegment(
                                  value: MockAccountType.newUser,
                                  label: Text('New User'),
                                ),
                              ],
                              selected: {_mockAccountType},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _mockAccountType = selection.first;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: 220,
                              child: FilledButton(
                                onPressed: _continue,
                                child: const Text('Continue'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
