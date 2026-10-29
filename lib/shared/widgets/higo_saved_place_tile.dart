import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';
import '../../features/rider/account/rider_saved_places_store.dart';

class HiGoSavedPlaceTile extends StatelessWidget {
  const HiGoSavedPlaceTile({
    super.key,
    required this.place,
    required this.onTap,
  });

  final RiderSavedPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (place.type) {
      SavedPlaceType.home => Icons.home_outlined,
      SavedPlaceType.work => Icons.work_outline,
      SavedPlaceType.custom => Icons.bookmark_outline,
    };

    return SizedBox(
      width: 132,
      height: 68,
      child: Material(
        color: const Color(0xFFF2EFFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8D0FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: HiGoTheme.primary, size: 17),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        place.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  place.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.15,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
