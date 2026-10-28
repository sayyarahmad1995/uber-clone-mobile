import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'driver_arrival_screen.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'ride_category.dart';

class DriverConfirmationScreen extends StatelessWidget {
  const DriverConfirmationScreen({
    super.key,
    required this.locations,
    required this.offer,
    required this.rideCategory,
  });

  final SelectedLocations locations;
  final MockDriverOffer offer;
  final RideCategory rideCategory;

  void _confirm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverArrivalScreen(
          locations: locations,
          offer: offer,
          rideCategory: rideCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm driver',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF1EBFF),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0, 0.3, 0.75, 1],
                  colors: [
                    Color(0xFFF1EBFF),
                    Colors.white,
                    Colors.white,
                    Color(0xFFE8F3FF),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Your selected offer',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'City Ride · ${rideCategory.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: HiGoTheme.primary,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Review the driver details '
                            'before continuing.',
                            style: TextStyle(
                              fontSize: 13,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: HiGoTheme.border),
                            ),
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Color(0xFFF0EDFF),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 34,
                                    color: HiGoTheme.primary,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  offer.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: HiGoTheme.navy,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  offer.vehicle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFEDA72B),
                                      size: 18,
                                    ),
                                    Text(
                                      ' ${offer.rating.toStringAsFixed(1)}'
                                      ' · ${offer.arrivalMinutes} min away',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: HiGoTheme.navy,
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 32),

                                const Text(
                                  'DRIVER OFFER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Rs ${offer.farePkr}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: HiGoTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          _LocationSummary(
                            title: 'Pickup',
                            value: locations.pickup,
                            icon: Icons.radio_button_checked,
                          ),

                          const SizedBox(height: 16),

                          _LocationSummary(
                            title: 'Destination',
                            value: locations.destination,
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FilledButton(
                    onPressed: () => _confirm(context),
                    child: const Text('Confirm Selection'),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Demo only · No bid acceptance '
                    'or driver assignment',
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

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: HiGoTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HiGoTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
