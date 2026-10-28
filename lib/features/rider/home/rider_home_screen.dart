import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../booking/location_selection_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String? _pickup;
  String? _destination;

  // Mock locations, to be replaced by actual
  // recent trips and named places later.
  static const List<_RecentLocation> _recentLocations = [
    _RecentLocation(name: 'Centaurus Mall', address: 'F-8, Islamabad'),
    _RecentLocation(name: 'Faisal Mosque', address: 'E-8, Islamabad'),
    _RecentLocation(name: 'F-10 Markaz', address: 'F-10, Islamabad'),
  ];

  Future<void> _openLocationSelection({String? initialDestination}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LocationSelectionScreen(
          initialPickup: _pickup,
          initialDestination: initialDestination ?? _destination,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Temporary map background.
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_map.png',
              fit: BoxFit.cover,
            ),
          ),

          // Draggable Rider Home panel.
          DraggableScrollableSheet(
            initialChildSize: 0.52,
            minChildSize: 0.52,
            maxChildSize: 0.80,
            snap: true,
            snapSizes: const [0.52],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE2EE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: HiGoTheme.navy,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Main destination search.
                    Material(
                      color: const Color(0xFFF8F9FD),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _openLocationSelection,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: HiGoTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: HiGoTheme.primary,
                                size: 23,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _destination ?? 'Search destination',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _destination == null
                                        ? HiGoTheme.secondaryText
                                        : HiGoTheme.navy,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 15,
                                color: HiGoTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Our services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Only the currently supported service.
                    Row(
                      children: [
                        _ServiceTile(
                          icon: Icons.directions_car_filled,
                          title: 'City Ride',
                          onTap: _openLocationSelection,
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent locations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Full location history '
                                  'will be available later.',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'See all',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    ..._recentLocations.map(
                      (location) => _RecentLocationTile(
                        location: location,
                        onTap: () => _openLocationSelection(
                          initialDestination: '${location.name}, Islamabad',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentLocation {
  const _RecentLocation({required this.name, required this.address});

  final String name;
  final String address;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8D0FF)),
        ),
        child: Column(
          children: [
            Icon(icon, color: HiGoTheme.primary, size: 27),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: HiGoTheme.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentLocationTile extends StatelessWidget {
  const _RecentLocationTile({required this.location, required this.onTap});

  final _RecentLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF1EEFF),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.history, color: HiGoTheme.primary, size: 21),
      ),
      title: Text(
        location.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: HiGoTheme.navy,
        ),
      ),
      subtitle: Text(
        location.address,
        style: const TextStyle(fontSize: 12, color: HiGoTheme.secondaryText),
      ),
      trailing: const Icon(
        Icons.north_west,
        size: 18,
        color: HiGoTheme.secondaryText,
      ),
    );
  }
}
