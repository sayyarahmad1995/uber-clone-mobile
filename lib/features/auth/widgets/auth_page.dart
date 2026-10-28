import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    required this.child,
    required this.onEditPhone,
  });

  final String title;
  final String subtitle;
  final String phoneNumber;
  final Widget child;
  final VoidCallback onEditPhone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0, 0.3, 0.7, 1],
                    colors: [
                      Color(0xFFF2E9FF),
                      Colors.white,
                      Colors.white,
                      Color(0xFFE7F3FF),
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
                      onPressed: onEditPhone,
                      icon: const Icon(Icons.arrow_back),
                      color: HiGoTheme.navy,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Verified phone number from the
                        // previous prototype step.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HiGoTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_android,
                                size: 19,
                                color: HiGoTheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  phoneNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).popUntil(
                                    (route) => route.settings.name == '/phone',
                                  );
                                },
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),
                        child,
                      ],
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

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: HiGoTheme.navy,
        ),
      ),
    );
  }
}
