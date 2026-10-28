import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/higo_theme.dart';
import 'account_checking_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 30;

  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsRemaining = _resendSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }

        if (_secondsRemaining == 0) {
          timer.cancel();
        }
      });
    });
  }

  void _resendCode() {
    if (_secondsRemaining > 0) return;

    _otpController.clear();

    setState(() {
      _startCountdown();
    });

    _focusNode.requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resend simulated. No SMS was sent.')),
    );
  }

  void _verifyCode() {
    final code = _otpController.text;

    if (code.length != _codeLength) return;

    _focusNode.unfocus();

    // UI prototype only.
    // Any six-digit code is accepted at this stage.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountCheckingScreen(phoneNumber: widget.phoneNumber),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _otpController.text;
    final isComplete = code.length == _codeLength;

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    final countdown =
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Soft Aurora background.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0.0, 0.28, 0.72, 1.0],
                    colors: [
                      Color(0xFFF1E9FF),
                      Colors.white,
                      Colors.white,
                      Color(0xFFE8F2FF),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back navigation.
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter verification code',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: HiGoTheme.navy,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Enter the 6-digit code sent to',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.phoneNumber,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: HiGoTheme.navy,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // One input, six visual boxes.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 8.0;

                            final boxWidth =
                                ((constraints.maxWidth - gap * 5) / _codeLength)
                                    .clamp(30.0, 54.0);

                            return Center(
                              child: SizedBox(
                                width: boxWidth * 6 + gap * 5,
                                height: 56,
                                child: Stack(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(_codeLength, (
                                        index,
                                      ) {
                                        final hasDigit = index < code.length;

                                        final isCurrent =
                                            _focusNode.hasFocus &&
                                            index ==
                                                code.length.clamp(
                                                  0,
                                                  _codeLength - 1,
                                                );

                                        return IgnorePointer(
                                          child: Container(
                                            width: boxWidth,
                                            height: 54,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isCurrent
                                                    ? HiGoTheme.primary
                                                    : HiGoTheme.border,
                                                width: isCurrent ? 1.6 : 1,
                                              ),
                                            ),
                                            child: Text(
                                              hasDigit ? code[index] : '',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w600,
                                                color: HiGoTheme.navy,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),

                                    // Actual editable input.
                                    Positioned.fill(
                                      child: TextField(
                                        controller: _otpController,
                                        focusNode: _focusNode,
                                        autofocus: true,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ],
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(
                                            _codeLength,
                                          ),
                                        ],
                                        style: const TextStyle(
                                          color: Colors.transparent,
                                          fontSize: 22,
                                        ),
                                        cursorColor: Colors.transparent,
                                        showCursor: false,
                                        decoration: const InputDecoration(
                                          filled: false,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          counterText: '',
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        maxLength: _codeLength,
                                        onChanged: (_) {
                                          setState(() {});
                                        },
                                        onSubmitted: (_) {
                                          _verifyCode();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 26),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                "Didn't receive the code?",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: HiGoTheme.secondaryText,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            TextButton(
                              onPressed: _secondsRemaining == 0
                                  ? _resendCode
                                  : null,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Resend',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            if (_secondsRemaining > 0)
                              Text(
                                countdown,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: HiGoTheme.secondaryText,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        FilledButton(
                          onPressed: isComplete ? _verifyCode : null,
                          child: const Text('Verify & Continue'),
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
