import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';

class DriverActivityScreen extends StatelessWidget {
  const DriverActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final trips = store.completedTrips;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFF1EAFF),
                  Colors.white,
                  Colors.white,
                  Color(0xFFEAF3FF),
                ],
                stops: [0, 0.3, 0.7, 1],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Trips and earnings · Demo',
                  style: TextStyle(
                    fontSize: 13,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ActivityStat(
                        icon: Icons.directions_car,
                        label: 'Trips',
                        value: '${trips.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActivityStat(
                        icon: Icons.account_balance_wallet,
                        label: 'Earnings',
                        value: 'Rs ${store.totalDemoEarningsPkr}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Completed rides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: HiGoTheme.navy,
                  ),
                ),
                const SizedBox(height: 14),
                if (trips.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 46,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HiGoTheme.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history, size: 40, color: HiGoTheme.primary),
                        SizedBox(height: 14),
                        Text(
                          'No completed trips yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Completed demo trips will '
                          'appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...trips.map(
                    (trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompletedTripCard(trip: trip),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: HiGoTheme.primary, size: 23),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: HiGoTheme.navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: HiGoTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedTripCard extends StatelessWidget {
  const _CompletedTripCard({required this.trip});

  final MockCompletedDriverTrip trip;

  @override
  Widget build(BuildContext context) {
    final date = trip.completedAt;

    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF159653),
                size: 19,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Completed · Demo',
                  style: TextStyle(
                    color: Color(0xFF148A4F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: HiGoTheme.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _LocationLine(
            icon: Icons.radio_button_checked,
            value: trip.request.pickup,
          ),
          const SizedBox(height: 10),
          _LocationLine(
            icon: Icons.location_on,
            value: trip.request.destination,
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.request.riderName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HiGoTheme.navy,
                  ),
                ),
              ),
              Text(
                'Rs ${trip.farePkr}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trip.riderRating == null
                ? 'Rider not rated'
                : 'Your rider rating: '
                      '${trip.riderRating}/5',
            style: const TextStyle(
              fontSize: 12,
              color: HiGoTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: HiGoTheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: HiGoTheme.navy),
          ),
        ),
      ],
    );
  }
}
