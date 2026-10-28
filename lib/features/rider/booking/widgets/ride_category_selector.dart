import 'package:flutter/material.dart';

import '../../../../app/higo_theme.dart';
import '../ride_category.dart';

class RideCategorySelector extends StatelessWidget {
  const RideCategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<RideCategory> categories;
  final String? selectedId;
  final ValueChanged<RideCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text(
        'No ride categories available.',
        style: TextStyle(fontSize: 13, color: HiGoTheme.secondaryText),
      );
    }

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedId;

          return Material(
            color: selected ? const Color(0xFFF1EEFF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected(category),
              child: Container(
                width: 124,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? HiGoTheme.primary : HiGoTheme.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(category.icon, size: 25, color: HiGoTheme.primary),
                        Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          size: 18,
                          color: selected
                              ? HiGoTheme.primary
                              : HiGoTheme.border,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.description,
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
            ),
          );
        },
      ),
    );
  }
}
