import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../../../shared/widgets/higo_saved_place_tile.dart';
import '../account/rider_saved_places_store.dart';
import '../booking/location_selection_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String? _pickup;
  String? _destination;

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
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_map.png',
              fit: BoxFit.cover,
            ),
          ),
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
                    10,
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

                    const SizedBox(height: 12),

                    const Text(
                      'Where to?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HiGoTheme.navy,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Material(
                      color: const Color(0xFFF8F9FD),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _openLocationSelection,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
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
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _destination ?? 'Search destination',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _destination == null
                                        ? HiGoTheme.secondaryText
                                        : HiGoTheme.navy,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 13,
                                color: HiGoTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Our services',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _ServiceTile(
                          icon: Icons.directions_car_filled,
                          title: 'City Ride',
                          onTap: _openLocationSelection,
                        ),
                      ],
                    ),

                    AnimatedBuilder(
                      animation: riderSavedPlacesStore,
                      builder: (context, _) {
                        final savedPlaces = riderSavedPlacesStore.places;

                        if (savedPlaces.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final orderedPlaces = [
                          ...savedPlaces.where(
                            (p) => p.type == SavedPlaceType.home,
                          ),
                          ...savedPlaces.where(
                            (p) => p.type == SavedPlaceType.work,
                          ),
                          ...savedPlaces.where(
                            (p) => p.type == SavedPlaceType.custom,
                          ),
                        ];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const Text(
                              'Saved places',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 68,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.zero,
                                itemCount: orderedPlaces.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final place = orderedPlaces[index];
                                  return HiGoSavedPlaceTile(
                                    place: place,
                                    onTap: () => _openLocationSelection(
                                      initialDestination: place.address,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent locations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8D0FF)),
        ),
        child: Column(
          children: [
            Icon(icon, color: HiGoTheme.primary, size: 23),
            const SizedBox(height: 5),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1EEFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                color: HiGoTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HiGoTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.north_west,
              size: 16,
              color: HiGoTheme.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
