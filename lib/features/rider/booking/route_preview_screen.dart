import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'location_selection_screen.dart';
import 'ride_category_selection_screen.dart';

class RoutePreviewScreen extends StatefulWidget {
  const RoutePreviewScreen({super.key, required this.initialLocations});

  final SelectedLocations initialLocations;

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  late SelectedLocations _locations;

  @override
  void initState() {
    super.initState();
    _locations = widget.initialLocations;
  }

  Future<void> _editLocations() async {
    final result = await Navigator.of(context).push<SelectedLocations>(
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          initialPickup: _locations.pickup,
          initialDestination: _locations.destination,
          returnSelection: true,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _locations = result;
    });
  }

  void _chooseRide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RideCategorySelectionScreen(locations: _locations),
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

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: HiGoTheme.navy,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Route Preview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.65,
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.paddingOf(context).bottom,
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
                    const SizedBox(height: 20),
                    const Text(
                      'Your route',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Review your locations before '
                      'choosing a ride.',
                      style: TextStyle(
                        fontSize: 13,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LocationRow(
                      icon: Icons.radio_button_checked,
                      label: 'Pickup',
                      value: _locations.pickup,
                      color: HiGoTheme.primary,
                    ),
                    const SizedBox(height: 16),
                    _LocationRow(
                      icon: Icons.location_on,
                      label: 'Destination',
                      value: _locations.destination,
                      color: const Color(0xFFED5A65),
                    ),
                    const SizedBox(height: 22),
                    OutlinedButton.icon(
                      onPressed: _editLocations,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit locations'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _chooseRide,
                      child: const Text('Choose Ride'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HiGoTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
