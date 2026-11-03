import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/higo_theme.dart';

/// Illustrative map preview only. Positions are not live GPS coordinates.
class NearbyDriversMockMap extends StatelessWidget {
  const NearbyDriversMockMap({super.key, required this.scanning});

  /// The pulse is visible while no driver bids are available.
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final enoughRoomForCars = constraints.maxHeight >= 230;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/welcome_map.png',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
            const ColoredBox(color: Color(0x1AFFFFFF)),
            IgnorePointer(
              child: Stack(
                children: [
                  if (enoughRoomForCars) ...const [
                    Align(
                      alignment: Alignment(-0.72, -0.61),
                      child: _MockDriverMarker(id: '1'),
                    ),
                    Align(
                      alignment: Alignment(0.74, -0.39),
                      child: _MockDriverMarker(id: '2'),
                    ),
                    Align(
                      alignment: Alignment(-0.75, 0.54),
                      child: _MockDriverMarker(id: '3'),
                    ),
                    Align(
                      alignment: Alignment(0.73, 0.64),
                      child: _MockDriverMarker(id: '4'),
                    ),
                  ],
                  Align(
                    alignment: const Alignment(0, 0.12),
                    child: _MockRiderLocation(scanning: scanning),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MockRiderLocation extends StatefulWidget {
  const _MockRiderLocation({required this.scanning});

  final bool scanning;

  @override
  State<_MockRiderLocation> createState() => _MockRiderLocationState();
}

class _MockRiderLocationState extends State<_MockRiderLocation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool get _shouldAnimate =>
      widget.scanning && !MediaQuery.of(context).disableAnimations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant _MockRiderLocation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (_shouldAnimate) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.scanning
          ? 'Scanning for nearby drivers, demo locations'
          : 'Rider location preview, not live GPS',
      child: Column(
        key: const Key('mock-rider-location'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 172,
            height: 172,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.scanning)
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      key: const Key('rider-scanning-animation'),
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        key: const Key('rider-scanning-pulses'),
                        size: const Size(172, 172),
                        painter: RiderScanningPulsePainter(
                          progress: _shouldAnimate ? _pulse.value : 0,
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x400E1640),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: HiGoTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    color: Color(0x220E1640),
                  ),
                ],
              ),
              child: const Text(
                'You · demo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HiGoTheme.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two offset expanding rings. A CustomPainter avoids rebuilding the map
/// or driver cards on every animation frame.
class RiderScanningPulsePainter extends CustomPainter {
  const RiderScanningPulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.48;
    const minRadius = 22.0;

    for (var index = 0; index < 2; index++) {
      final phase = (progress + index * 0.5) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * phase;
      final alpha = (0.26 * (1.0 - phase)).clamp(0.0, 1.0).toDouble();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - phase * 1.0
        ..color = HiGoTheme.primary.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RiderScanningPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MockDriverMarker extends StatelessWidget {
  const _MockDriverMarker({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Illustrative nearby driver',
      child: Container(
        key: Key('mock-driver-$id'),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: HiGoTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x290E1640),
              blurRadius: 9,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_car,
          color: HiGoTheme.secondaryText,
          size: 24,
        ),
      ),
    );
  }
}
