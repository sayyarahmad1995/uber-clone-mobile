import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'rating_review_screen.dart';
import 'ride_category.dart';

class CashPaymentScreen extends StatelessWidget {
  const CashPaymentScreen({
    super.key,
    required this.locations,
    required this.offer,
    required this.rideCategory,
  });

  final SelectedLocations locations;
  final MockDriverOffer offer;
  final RideCategory rideCategory;

  String get _formattedFare {
    final digits = offer.farePkr.toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  void _continue(BuildContext context) {
    // Demo only: this does not confirm that the
    // driver received payment.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RatingReviewScreen(
          driverName: offer.name,
          vehicle: offer.vehicle,
          farePkr: offer.farePkr,
          rideCategoryName: rideCategory.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0, 0.3, 0.72, 1],
                  colors: [
                    Color(0xFFF1EAFF),
                    Colors.white,
                    Colors.white,
                    Color(0xFFEAF3FF),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Color(0xFFF0EDFF),
                              child: Icon(
                                Icons.payments_outlined,
                                size: 36,
                                color: HiGoTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Trip completed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your cash payment summary',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: HiGoTheme.border),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'AGREED TRIP FARE · DEMO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Rs $_formattedFare',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: HiGoTheme.primary,
                                  ),
                                ),
                                const Divider(height: 36),
                                const _DetailRow(
                                  label: 'Payment method',
                                  value: 'Cash',
                                ),
                                const SizedBox(height: 14),
                                const _DetailRow(
                                  label: 'Payment status',
                                  value: 'Not verified · Demo',
                                ),
                                const SizedBox(height: 14),
                                _DetailRow(label: 'Driver', value: offer.name),
                                const SizedBox(height: 14),
                                _DetailRow(
                                  label: 'Ride category',
                                  value: rideCategory.name,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Pay your agreed fare directly '
                            'to the driver.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: HiGoTheme.navy,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The driver will confirm payment '
                            'receipt through the actual trip '
                            'workflow when API integration '
                            'is enabled.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Trip: ${locations.pickup} → '
                            '${locations.destination}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _continue(context),
                    child: const Text('Continue to Rating'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'UI preview only · No payment confirmed',
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
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: HiGoTheme.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HiGoTheme.navy,
            ),
          ),
        ),
      ],
    );
  }
}
