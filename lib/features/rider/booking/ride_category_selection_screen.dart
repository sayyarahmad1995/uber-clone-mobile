import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'driver_offers_screen.dart';
import 'location_selection_screen.dart';
import 'ride_category.dart';

class RideCategorySelectionScreen extends StatefulWidget {
  const RideCategorySelectionScreen({
    super.key,
    required this.locations,
    this.categories = mockRideCategories,
  });

  final SelectedLocations locations;
  final List<RideCategory> categories;

  @override
  State<RideCategorySelectionScreen> createState() =>
      _RideCategorySelectionScreenState();
}

class _RideCategorySelectionScreenState
    extends State<RideCategorySelectionScreen> {
  String? _selectedCategoryId;

  RideCategory? get _selectedCategory {
    for (final category in widget.categories) {
      if (category.id == _selectedCategoryId) {
        return category;
      }
    }
    return null;
  }

  void _requestRide() {
    final category = _selectedCategory;
    if (category == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverOffersScreen(
          locations: widget.locations,
          rideCategory: category,
        ),
      ),
    );
  }

  String _fareText(int? amount) {
    if (amount == null) return 'N/A';

    final digits = amount.toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return 'Rs $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCategory;

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
                      'City Ride',
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
                maxHeight: MediaQuery.sizeOf(context).height * 0.78,
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
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),

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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose your ride',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.locations.pickup} → '
                            '${widget.locations.destination}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Flexible(
                      fit: FlexFit.loose,
                      child: widget.categories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No ride categories available.',
                                  style: TextStyle(
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              itemCount: widget.categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final category = widget.categories[index];

                                return _CategoryCard(
                                  category: category,
                                  selected: category.id == _selectedCategoryId,
                                  fareText: _fareText(
                                    category.estimatedFarePkr,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId = category.id;
                                    });
                                  },
                                );
                              },
                            ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: selected == null ? null : _requestRide,
                            child: const Text('Request Ride'),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Estimated fares are examples. '
                            'Drivers may submit different offers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.fareText,
    required this.onTap,
  });

  final RideCategory category;
  final bool selected;
  final String fareText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF6F4FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HiGoTheme.primary : HiGoTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: HiGoTheme.primary, size: 26),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fareText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: HiGoTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Estimate',
                    style: TextStyle(
                      fontSize: 10,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? HiGoTheme.primary : HiGoTheme.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
