import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'rider_ride_history_store.dart';

class RiderRidesScreen extends StatelessWidget {
  const RiderRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Rides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: riderRideHistoryStore,
        builder: (context, _) {
          final rides = riderRideHistoryStore.completedRides;

          if (rides.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.route_outlined,
                      color: HiGoTheme.primary,
                      size: 44,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'No ride history yet',
                      style: TextStyle(
                        color: HiGoTheme.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your completed rides will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HiGoTheme.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: rides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ride = rides[index];
              final date = ride.completedAt;
              final dateText =
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/'
                  '${date.year}';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HiGoTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: HiGoTheme.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: HiGoTheme.navy,
                            ),
                          ),
                        ),
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _DetailLine(
                      icon: Icons.radio_button_checked,
                      label: ride.pickup,
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      icon: Icons.location_on_outlined,
                      label: ride.destination,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${ride.category} · ${ride.driverName}',
                      style: const TextStyle(
                        color: HiGoTheme.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.vehicle,
                      style: const TextStyle(
                        color: HiGoTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Agreed fare · Cash not verified',
                          style: TextStyle(
                            color: HiGoTheme.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Rs ${ride.farePkr}',
                          style: const TextStyle(
                            color: HiGoTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HiGoTheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: HiGoTheme.navy),
          ),
        ),
      ],
    );
  }
}
