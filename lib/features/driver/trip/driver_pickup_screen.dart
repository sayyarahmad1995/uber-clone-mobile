import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'driver_rider_otp_screen.dart';

enum DemoPickupStatus { enRoute, arrived }

class DriverPickupScreen extends StatefulWidget {
  const DriverPickupScreen({
    super.key,
    required this.request,
    required this.bid,
  });

  final MockRideRequest request;
  final MockDriverBid bid;

  @override
  State<DriverPickupScreen> createState() => _DriverPickupScreenState();
}

class _DriverPickupScreenState extends State<DriverPickupScreen> {
  late DemoPickupStatus _status;

  @override
  void initState() {
    super.initState();

    final stage = DriverDemoStore.instance.assignmentStage(widget.request.id);

    _status = stage == DemoAssignmentStage.arrived
        ? DemoPickupStatus.arrived
        : DemoPickupStatus.enRoute;
  }

  @override
  Widget build(BuildContext context) {
    final arrived = _status == DemoPickupStatus.arrived;

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
            alignment: Alignment(0, -0.30),
            child: Icon(Icons.location_pin, color: HiGoTheme.primary, size: 48),
          ),

          const Align(
            alignment: Alignment(-0.4, -0.05),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: HiGoTheme.primary,
              child: Icon(Icons.directions_car, color: Colors.white, size: 22),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    elevation: 2,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      arrived ? 'Arrived · Demo' : 'To pickup · Demo',
                      style: TextStyle(
                        color: arrived
                            ? const Color(0xFF128450)
                            : HiGoTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
                    color: Color(0x20000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
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
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            arrived ? Icons.check_circle : Icons.navigation,
                            color: arrived
                                ? const Color(0xFF148953)
                                : HiGoTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              arrived
                                  ? 'Arrived at pickup'
                                  : 'Navigate to pickup',
                              style: const TextStyle(
                                color: HiGoTheme.navy,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        arrived
                            ? 'Verify the rider before starting the trip.'
                            : 'Head to the rider\'s pickup location.',
                        style: const TextStyle(
                          color: HiGoTheme.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEFECFF),
                            child: Icon(Icons.person, color: HiGoTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.request.riderName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: HiGoTheme.navy,
                              ),
                            ),
                          ),
                          Text(
                            'Rs ${widget.bid.farePkr}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PICKUP',
                        style: TextStyle(
                          color: HiGoTheme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.request.pickup,
                        style: const TextStyle(
                          color: HiGoTheme.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'DESTINATION',
                        style: TextStyle(
                          color: HiGoTheme.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.request.destination,
                        style: const TextStyle(
                          color: HiGoTheme.navy,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (!arrived) {
                              DriverDemoStore.instance.arriveAtDemoPickup(
                                widget.request.id,
                              );

                              setState(() {
                                _status = DemoPickupStatus.arrived;
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DriverRiderOtpScreen(
                                    request: widget.request,
                                    bid: widget.bid,
                                  ),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DriverRiderOtpScreen(
                                    request: widget.request,
                                    bid: widget.bid,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            arrived ? 'Verify Rider OTP' : 'Demo: Mark Arrived',
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Static map · No live navigation',
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
