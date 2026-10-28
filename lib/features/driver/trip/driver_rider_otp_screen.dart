import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'driver_trip_in_progress_screen.dart';

class DriverRiderOtpScreen extends StatefulWidget {
  const DriverRiderOtpScreen({
    super.key,
    required this.request,
    required this.bid,
  });

  final MockRideRequest request;
  final MockDriverBid bid;

  @override
  State<DriverRiderOtpScreen> createState() => _DriverRiderOtpScreenState();
}

class _DriverRiderOtpScreenState extends State<DriverRiderOtpScreen> {
  static const _demoOtp = '1234';

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _showError = false;
  bool _verified = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verify() {
    if (_controller.text == _demoOtp) {
      FocusScope.of(context).unfocus();
      setState(() {
        _verified = true;
        _showError = false;
      });
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Rider', style: TextStyle(fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 34,
                backgroundColor: _verified
                    ? const Color(0xFFE4F7EC)
                    : const Color(0xFFEFECFF),
                child: Icon(
                  _verified ? Icons.verified_user : Icons.lock_outline,
                  color: _verified
                      ? const Color(0xFF13894F)
                      : HiGoTheme.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _verified ? 'Rider verified' : 'Enter rider OTP',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _verified
                    ? 'Mock pickup verification succeeded.'
                    : 'Ask ${widget.request.riderName} '
                          'for the four-digit pickup code.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 30),
              if (!_verified) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _focusNode.requestFocus(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            setState(() {
                              _showError = false;
                            });
                          },
                          decoration: const InputDecoration(counterText: ''),
                        ),
                      ),
                      IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final code = _controller.text;
                            final value = index < code.length
                                ? code[index]
                                : '';

                            return Container(
                              width: 54,
                              height: 60,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _showError
                                      ? const Color(0xFFB42335)
                                      : HiGoTheme.border,
                                ),
                              ),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: HiGoTheme.navy,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showError) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Incorrect demo code. Try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB42335), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Demo verification code: 1234',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: HiGoTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _controller.text.length == 4 ? _verify : null,
                  child: const Text('Verify OTP'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: HiGoTheme.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.request.pickup,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Agreed fare: Rs ${widget.bid.farePkr}',
                        style: const TextStyle(color: HiGoTheme.secondaryText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                FilledButton(
                  onPressed: () {
                    DriverDemoStore.instance.startDemoTrip(widget.request.id);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverTripInProgressScreen(
                          request: widget.request,
                          bid: widget.bid,
                        ),
                      ),
                    );
                  },
                  child: const Text('Start Trip · Demo'),
                ),

                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
