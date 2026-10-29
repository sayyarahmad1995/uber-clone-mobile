import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'cash_payment_screen.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'ride_category.dart';
import '../rides/rider_ride_history_store.dart';

class TripInProgressScreen extends StatelessWidget {
  const TripInProgressScreen({
    super.key,
    required this.locations,
    required this.offer,
    required this.rideCategory,
  });

  final SelectedLocations locations;
  final MockDriverOffer offer;
  final RideCategory rideCategory;

  void _completeDemoTrip(BuildContext context) {
    final tripRoute = ModalRoute.of(context);

    if (tripRoute == null) return;

    riderRideHistoryStore.recordCompletedRide(
      tripKey: tripRoute,
      ride: CompletedRiderRide(
        pickup: locations.pickup,
        destination: locations.destination,
        category: rideCategory.name,
        driverName: offer.name,
        vehicle: offer.vehicle,
        farePkr: offer.farePkr,
        completedAt: DateTime.now(),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CashPaymentScreen(
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_map.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Trip in progress · Demo',
                    style: TextStyle(
                      color: HiGoTheme.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Enjoy your ride',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${offer.name} · ${offer.vehicle}',
                        style: const TextStyle(
                          color: HiGoTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'City Ride · ${rideCategory.name}',
                        style: const TextStyle(
                          color: HiGoTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _TripStop(
                        label: 'Pickup',
                        value: locations.pickup,
                        icon: Icons.radio_button_checked,
                      ),
                      const SizedBox(height: 14),
                      _TripStop(
                        label: 'Destination',
                        value: locations.destination,
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => _completeDemoTrip(context),
                        child: const Text('Demo: Complete Trip'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Trip completion is simulated.',
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
          ),
        ],
      ),
    );
  }
}

class _TripStop extends StatelessWidget {
  const _TripStop({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HiGoTheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: HiGoTheme.navy,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
