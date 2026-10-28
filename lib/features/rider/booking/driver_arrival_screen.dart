import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'ride_category.dart';
import 'trip_in_progress_screen.dart';

enum _DemoArrivalStatus { assigned, approaching, arrived }

class DriverArrivalScreen extends StatefulWidget {
  const DriverArrivalScreen({
    super.key,
    required this.locations,
    required this.offer,
    required this.rideCategory,
  });

  final SelectedLocations locations;
  final MockDriverOffer offer;
  final RideCategory rideCategory;

  @override
  State<DriverArrivalScreen> createState() => _DriverArrivalScreenState();
}

class _DriverArrivalScreenState extends State<DriverArrivalScreen> {
  _DemoArrivalStatus _status = _DemoArrivalStatus.assigned;

  String get _statusTitle => switch (_status) {
    _DemoArrivalStatus.assigned => 'Driver confirmed',
    _DemoArrivalStatus.approaching => 'Driver is on the way',
    _DemoArrivalStatus.arrived => 'Driver has arrived',
  };

  String get _statusDescription => switch (_status) {
    _DemoArrivalStatus.assigned =>
      'Your selected driver is assigned in this demo.',
    _DemoArrivalStatus.approaching =>
      'Driver approaching your pickup location.',
    _DemoArrivalStatus.arrived =>
      'Your driver is waiting at the pickup location.',
  };

  void _startDemoTrip() {
    if (_status != _DemoArrivalStatus.arrived) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TripInProgressScreen(
          locations: widget.locations,
          offer: widget.offer,
          rideCategory: widget.rideCategory,
        ),
      ),
    );
  }

  void _advanceDemo() {
    setState(() {
      _status = switch (_status) {
        _DemoArrivalStatus.assigned => _DemoArrivalStatus.approaching,
        _DemoArrivalStatus.approaching => _DemoArrivalStatus.arrived,
        _DemoArrivalStatus.arrived => _DemoArrivalStatus.arrived,
      };
    });
  }

  Future<void> _exitDemo() async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit ride preview?'),
        content: const Text(
          'This will end the simulated ride '
          'preview and return to Rider Home.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit Preview'),
          ),
        ],
      ),
    );

    if (!mounted || exit != true) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final arrived = _status == _DemoArrivalStatus.arrived;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exitDemo();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/welcome_map.png',
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 2,
                    child: IconButton(
                      onPressed: _exitDemo,
                      icon: const Icon(Icons.close),
                      color: HiGoTheme.navy,
                    ),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  18 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 22,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
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

                      Text(
                        _statusTitle,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: HiGoTheme.navy,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        _statusDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFFF0EDFF),
                            child: Icon(
                              Icons.person_outline,
                              color: HiGoTheme.primary,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.offer.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.offer.vehicle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.rideCategory.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: HiGoTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'Rs ${widget.offer.farePkr}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 28),

                      Text(
                        'Pickup: ${widget.locations.pickup}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: HiGoTheme.navy,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Destination: '
                        '${widget.locations.destination}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: HiGoTheme.navy,
                        ),
                      ),

                      const SizedBox(height: 22),

                      FilledButton(
                        onPressed: arrived ? _startDemoTrip : _advanceDemo,
                        child: Text(switch (_status) {
                          _DemoArrivalStatus.assigned =>
                            'Demo: Driver Approaching',
                          _DemoArrivalStatus.approaching =>
                            'Demo: Driver Arrived',
                          _DemoArrivalStatus.arrived => 'Demo: Start Trip',
                        }),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _exitDemo,
                        child: const Text('Exit Preview'),
                      ),

                      const Text(
                        'Simulated trip status · '
                        'No GPS or driver connection',
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
          ],
        ),
      ),
    );
  }
}
