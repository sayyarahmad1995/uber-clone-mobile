import 'package:flutter/material.dart';

import '../../../../app/higo_theme.dart';

/// A visual-only map preview for the mock booking flow.
///
/// The background is an existing static image. These marker positions are
/// deliberately illustrative, not GPS coordinates or live driver presence.
class NearbyDriversMockMap extends StatelessWidget {
  const NearbyDriversMockMap({super.key, required this.showWaitingHint});

  final bool showWaitingHint;

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
                  const Align(
                    alignment: Alignment(0, 0.12),
                    child: _MockRiderLocation(),
                  ),
                ],
              ),
            ),
            if (showWaitingHint)
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Center(
                  child: Container(
                    key: const Key('nearby-drivers-hint'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Color(0x180F1B4B),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 17,
                          color: HiGoTheme.primary,
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Looking for offers · Map preview',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: HiGoTheme.navy,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MockRiderLocation extends StatelessWidget {
  const _MockRiderLocation();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rider current location preview, not live GPS',
      child: Column(
        key: const Key('mock-rider-location'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HiGoTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: HiGoTheme.primary.withValues(alpha: 0.24),
                width: 2,
              ),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: HiGoTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Color(0x400E1640)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(blurRadius: 5, color: Color(0x220E1640)),
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
        ],
      ),
    );
  }
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
