import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';

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
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_outlined, color: HiGoTheme.primary, size: 44),
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
                'Your current and past rides '
                'will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HiGoTheme.secondaryText, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'UI demo',
                style: TextStyle(color: HiGoTheme.secondaryText, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
