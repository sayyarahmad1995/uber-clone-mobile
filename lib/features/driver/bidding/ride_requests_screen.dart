import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'submit_bid_screen.dart';
import 'active_bids_screen.dart';

class RideRequestsScreen extends StatelessWidget {
  const RideRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride requests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel_outlined),
            tooltip: 'Active bids',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActiveBidsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0, 0.3, 0.7, 1],
                  colors: [
                    Color(0xFFF0EAFF),
                    Colors.white,
                    Colors.white,
                    Color(0xFFEAF4FF),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final requests = store.availableRequests;

              if (!store.isOnline) {
                return const _EmptyInbox(
                  icon: Icons.power_settings_new,
                  title: 'You are offline',
                  description:
                      'Return to Driver Home and go online '
                      'to preview ride requests.',
                );
              }

              if (requests.isEmpty) {
                return const _EmptyInbox(
                  icon: Icons.inbox_outlined,
                  title: 'No new requests',
                  description: 'No unbid requests remain in this demo.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Text(
                    '${requests.length} new requests nearby',
                    style: const TextStyle(
                      fontSize: 13,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestCard(
                        request: request,
                        onOpen: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubmitBidScreen(request: request),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onOpen});

  final MockRideRequest request;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car,
                color: HiGoTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HiGoTheme.navy,
                  ),
                ),
              ),
              Text(
                '${request.durationMinutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StopRow(
            icon: Icons.radio_button_checked,
            value: request.pickup,
            color: HiGoTheme.primary,
          ),
          const SizedBox(height: 9),
          _StopRow(
            icon: Icons.location_on,
            value: request.destination,
            color: const Color(0xFFE74B60),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.route, size: 16, color: HiGoTheme.secondaryText),
              const SizedBox(width: 5),
              Text(
                '${request.distanceKm} km · Demo estimate',
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              const Spacer(),
              Text(
                'Rs ${request.estimatedFarePkr}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onOpen, child: const Text('View & Bid')),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
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

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: HiGoTheme.primary, size: 44),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HiGoTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: HiGoTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
