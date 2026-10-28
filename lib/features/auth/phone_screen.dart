import 'package:flutter/material.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

import '../../app/higo_theme.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  PhoneValidationResult? _phone;

  void _continue() {
    final phoneNumber = _phone?.e164;

    if (_phone?.isValid != true || phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: phoneNumber)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0.0, 0.26, 0.68, 1.0],
                    colors: [
                      Color(0xFFECE8FF),
                      Colors.white,
                      Colors.white,
                      Color(0xFFE7F2FF),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 68, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Let's get moving.",
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: HiGoTheme.navy,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Enter your phone number to\n'
                          'continue with HiGO.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),

                        const SizedBox(height: 42),

                        const Text(
                          'Phone number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HiGoTheme.navy,
                          ),
                        ),

                        const SizedBox(height: 10),

                        HiGoPhoneInput(
                          labelText: 'Phone number',
                          hintText: 'Enter your mobile number',
                          cursorColor: HiGoTheme.primary,
                          validateOnChange: false,
                          onChanged: (result) {
                            setState(() => _phone = result);
                          },
                        ),

                        const SizedBox(height: 28),

                        FilledButton(
                          onPressed: _continue,
                          child: const Text('Continue'),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          "We'll send you a verification code.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
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
