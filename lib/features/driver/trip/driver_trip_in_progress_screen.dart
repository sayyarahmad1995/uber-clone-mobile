import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'driver_cash_collection_screen.dart';

class DriverTripInProgressScreen extends StatelessWidget {
  const DriverTripInProgressScreen({
    super.key,
    required this.request,
    required this.bid,
  });

  final MockRideRequest request;
  final MockDriverBid bid;

  Future<void> _completeTrip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete trip?'),
        content: const Text(
          'This demo will move to cash collection. '
          'No trip status will be sent to the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Complete Trip'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    DriverDemoStore.instance.advanceToCashCollection(request.id);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DriverCashCollectionScreen(request: request, bid: bid),
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
          const Align(
            alignment: Alignment(0.3, -0.28),
            child: Icon(Icons.location_pin, size: 48, color: Color(0xFFEB5167)),
          ),
          const Align(
            alignment: Alignment(-0.25, 0.02),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: HiGoTheme.primary,
              child: Icon(Icons.directions_car, color: Colors.white),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Trip in progress · Demo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HiGoTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Color(0x22000000),
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 15, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: HiGoTheme.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.route, color: HiGoTheme.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Heading to destination',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'DESTINATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        request.destination,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const Divider(height: 28),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEFECFF),
                            child: Icon(Icons.person, color: HiGoTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request.riderName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: HiGoTheme.navy,
                              ),
                            ),
                          ),
                          Text(
                            'Rs ${bid.farePkr}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${request.distanceKm} km · '
                        '${request.durationMinutes} min '
                        '· Mock estimate',
                        style: const TextStyle(
                          fontSize: 12,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => _completeTrip(context),
                        child: const Text('Demo: Complete Trip'),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Static map · No live tracking',
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
