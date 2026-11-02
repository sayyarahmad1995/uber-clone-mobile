import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'driver_arrival_screen.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'ride_category.dart';

/// Only the mock client uses this handshake. The existing Go marketplace
/// contract assigns a trip on rider selection and must not be called here
/// until a real driver-confirmation contract exists.
enum DriverConfirmationResult { confirmed, declined, expired, cancelled }

class DriverConfirmationScreen extends StatefulWidget {
  const DriverConfirmationScreen({
    super.key,
    required this.locations,
    required this.offer,
    required this.rideCategory,
  });

  final SelectedLocations locations;
  final MockDriverOffer offer;
  final RideCategory rideCategory;

  @override
  State<DriverConfirmationScreen> createState() =>
      _DriverConfirmationScreenState();
}

class _DriverConfirmationScreenState extends State<DriverConfirmationScreen> {
  static const int _timeoutSeconds = 20;
  Timer? _timer;
  int _secondsLeft = _timeoutSeconds;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _finishing) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        _finish(DriverConfirmationResult.expired);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _finish(DriverConfirmationResult result) {
    if (!mounted || _finishing) return;
    _timer?.cancel();
    setState(() => _finishing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _simulateConfirmed() {
    if (!mounted || _finishing) return;
    _timer?.cancel();
    _finishing = true;
    // Only the explicit mock confirmation moves to the arrival screen.
    Navigator.of(context)
        .pushReplacement<DriverConfirmationResult, DriverConfirmationResult>(
          MaterialPageRoute<DriverConfirmationResult>(
            builder: (_) => DriverArrivalScreen(
              locations: widget.locations,
              offer: widget.offer,
              rideCategory: widget.rideCategory,
            ),
          ),
          result: DriverConfirmationResult.confirmed,
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return PopScope(
      canPop: _finishing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish(DriverConfirmationResult.cancelled);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Driver confirmation'),
          backgroundColor: const Color(0xFFF8F8FF),
          leading: IconButton(
            tooltip: 'Return to offers',
            onPressed: () => _finish(DriverConfirmationResult.cancelled),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF1F2FF),
                      Colors.white,
                      Color(0xFFEDF6FF),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            const Center(
                              child: SizedBox(
                                width: 46,
                                height: 46,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  color: HiGoTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Waiting for driver confirmation',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${offer.name} has not confirmed yet.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: HiGoTheme.secondaryText,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Confirmation expires in $_secondsLeft s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: HiGoTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: HiGoTheme.border),
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 29,
                                    backgroundColor: const Color(0xFFEDEEFF),
                                    foregroundImage: offer.photoAsset == null
                                        ? null
                                        : AssetImage(offer.photoAsset!),
                                    child: Text(
                                      offer.name
                                          .split(' ')
                                          .where((part) => part.isNotEmpty)
                                          .take(2)
                                          .map((part) => part[0].toUpperCase())
                                          .join(),
                                      style: const TextStyle(
                                        color: HiGoTheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    offer.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: HiGoTheme.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${offer.vehicle} · ${offer.vehicleColor}',
                                    style: const TextStyle(
                                      color: HiGoTheme.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '★ ${offer.rating.toStringAsFixed(1)} '
                                    '(${offer.reviewCount}) · '
                                    '${offer.arrivalMinutes} min away',
                                    style: const TextStyle(
                                      color: HiGoTheme.secondaryText,
                                    ),
                                  ),
                                  const Divider(height: 28),
                                  Text(
                                    formatOfferFare(offer.farePkr),
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800,
                                      color: HiGoTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _LocationRow(
                              label: 'Pickup',
                              value: widget.locations.pickup,
                              icon: Icons.location_on,
                            ),
                            const SizedBox(height: 12),
                            _LocationRow(
                              label: 'Destination',
                              value: widget.locations.destination,
                              icon: Icons.flag_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Demo controls · No driver network request is sent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HiGoTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _finishing ? null : _simulateConfirmed,
                      child: const Text('Demo: Driver confirms'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _finishing
                          ? null
                          : () => _finish(DriverConfirmationResult.declined),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Demo: Driver declines'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _finishing
                          ? null
                          : () => _finish(DriverConfirmationResult.cancelled),
                      child: const Text('Return to offers'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
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
        Icon(icon, color: HiGoTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: HiGoTheme.secondaryText),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: HiGoTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
