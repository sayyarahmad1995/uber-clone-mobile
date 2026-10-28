import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'route_preview_screen.dart';

class SelectedLocations {
  const SelectedLocations({required this.pickup, required this.destination});

  final String pickup;
  final String destination;
}

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({
    super.key,
    this.initialPickup,
    this.initialDestination,
    this.returnSelection = false,
  });

  final String? initialPickup;
  final String? initialDestination;
  final bool returnSelection;

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late final TextEditingController _pickupController;
  late final TextEditingController _destinationController;

  final _pickupFocus = FocusNode();
  final _destinationFocus = FocusNode();

  bool _editingPickup = false;

  static const _places = [
    'Centaurus Mall, Islamabad',
    'Faisal Mosque, Islamabad',
    'F-10 Markaz, Islamabad',
    'Blue Area, Islamabad',
    'Saddar, Rawalpindi',
    'Bahria Town, Rawalpindi',
  ];

  @override
  void initState() {
    super.initState();

    _pickupController = TextEditingController(text: widget.initialPickup ?? '');
    _destinationController = TextEditingController(
      text: widget.initialDestination ?? '',
    );

    _pickupController.addListener(_refresh);
    _destinationController.addListener(_refresh);

    _editingPickup = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_editingPickup) {
        _pickupFocus.requestFocus();
      } else {
        _destinationFocus.requestFocus();
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pickupController.removeListener(_refresh);
    _destinationController.removeListener(_refresh);
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  List<String> get _filteredPlaces {
    final query =
        (_editingPickup ? _pickupController.text : _destinationController.text)
            .trim()
            .toLowerCase();

    if (query.isEmpty) return _places;

    return _places
        .where((place) => place.toLowerCase().contains(query))
        .toList();
  }

  void _choosePlace(String place) {
    if (_editingPickup) {
      _pickupController.text = place;
      setState(() => _editingPickup = false);
      _destinationFocus.requestFocus();
    } else {
      _destinationController.text = place;
      _destinationFocus.unfocus();
    }
  }

  void _continue() {
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();

    if (pickup.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select pickup and destination.')),
      );
      return;
    }

    if (!_places.contains(pickup) || !_places.contains(destination)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select locations from the suggestions.')),
      );
      return;
    }

    if (pickup == destination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and destination must be different.'),
        ),
      );
      return;
    }

    final locations = SelectedLocations(
      pickup: pickup,
      destination: destination,
    );

    if (widget.returnSelection) {
      // Editing an existing route:
      // return the updated selection.
      Navigator.of(context).pop(locations);
      return;
    }

    // Starting a new booking:
    // open the dedicated Route Preview screen.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutePreviewScreen(initialLocations: locations),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _filteredPlaces;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFFF1EAFF),
                      Colors.white,
                      Colors.white,
                      Color(0xFFEAF3FF),
                    ],
                    stops: [0, 0.3, 0.7, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text(
                        'Choose locations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                  child: Column(
                    children: [
                      _LocationInput(
                        controller: _pickupController,
                        focusNode: _pickupFocus,
                        label: 'Pickup',
                        hint: 'Enter pickup location',
                        icon: Icons.radio_button_checked,
                        onTap: () {
                          setState(() => _editingPickup = true);
                        },
                      ),
                      const SizedBox(height: 12),
                      _LocationInput(
                        controller: _destinationController,
                        focusNode: _destinationFocus,
                        label: 'Destination',
                        hint: 'Where to?',
                        icon: Icons.location_on,
                        onTap: () {
                          setState(() => _editingPickup = false);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      (_editingPickup
                                  ? _pickupController.text
                                  : _destinationController.text)
                              .trim()
                              .isEmpty
                          ? 'Suggested locations'
                          : 'Search results',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: places.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching locations',
                            style: TextStyle(color: HiGoTheme.secondaryText),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: places.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 24,
                            endIndent: 24,
                          ),
                          itemBuilder: (context, index) {
                            final place = places[index];

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 3,
                              ),
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: HiGoTheme.primary,
                              ),
                              title: Text(
                                place,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: HiGoTheme.navy,
                                ),
                              ),
                              onTap: () => _choosePlace(place),
                            );
                          },
                        ),
                ),
                if (!keyboardVisible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _continue,
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  const _LocationInput({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onTap: onTap,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14, color: HiGoTheme.navy),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: HiGoTheme.primary, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: controller.clear,
              )
            : null,
      ),
    );
  }
}
