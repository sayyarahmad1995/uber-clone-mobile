import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'driver_rate_rider_screen.dart';

class DriverCashCollectionScreen extends StatefulWidget {
  const DriverCashCollectionScreen({
    super.key,
    required this.request,
    required this.bid,
  });

  final MockRideRequest request;
  final MockDriverBid bid;

  @override
  State<DriverCashCollectionScreen> createState() =>
      _DriverCashCollectionScreenState();
}

class _DriverCashCollectionScreenState
    extends State<DriverCashCollectionScreen> {
  bool _cashConfirmed = false;

  void _confirmCash() {
    if (_cashConfirmed) return;

    DriverDemoStore.instance.completeDemoTrip(
      widget.request,
      widget.bid.farePkr,
    );

    setState(() {
      _cashConfirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _cashConfirmed ? 'Payment Confirmed' : 'Collect Cash',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 22),
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: _cashConfirmed
                            ? const Color(0xFFE5F7EC)
                            : const Color(0xFFF0EDFF),
                        child: Icon(
                          _cashConfirmed
                              ? Icons.check_circle
                              : Icons.payments_outlined,
                          size: 43,
                          color: _cashConfirmed
                              ? const Color(0xFF159653)
                              : HiGoTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _cashConfirmed
                            ? 'Cash payment confirmed'
                            : 'Collect payment from rider',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        _cashConfirmed
                            ? 'Cash receipt recorded in '
                                  'the local demo.'
                            : 'Confirm the cash amount once '
                                  'you have received it.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: HiGoTheme.border),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'AGREED CASH FARE',
                              style: TextStyle(
                                fontSize: 12,
                                color: HiGoTheme.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Rs ${widget.bid.farePkr}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                const Text('Rider'),
                                const Spacer(),
                                Text(
                                  widget.request.riderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Payment method'),
                                const Spacer(),
                                const Text(
                                  'Cash · Demo',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('Status'),
                                const Spacer(),
                                Text(
                                  _cashConfirmed
                                      ? 'Confirmed · Demo'
                                      : 'Not confirmed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _cashConfirmed
                                        ? const Color(0xFF159653)
                                        : HiGoTheme.navy,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _cashConfirmed
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DriverRateRiderScreen(
                                  request: widget.request,
                                  farePkr: widget.bid.farePkr,
                                ),
                              ),
                            );
                          }
                        : _confirmCash,
                    child: Text(
                      _cashConfirmed
                          ? 'Continue to Rating'
                          : 'Demo: Confirm Cash Received',
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'No real payment verification or API call',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
