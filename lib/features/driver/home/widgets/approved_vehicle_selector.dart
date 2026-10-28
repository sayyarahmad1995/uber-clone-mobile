import 'package:flutter/material.dart';

import '../../../../app/higo_theme.dart';
import '../../models/mock_driver_vehicle.dart';
import '../../models/mock_ride_request.dart';

class ApprovedVehicleSelector extends StatelessWidget {
  const ApprovedVehicleSelector({super.key, required this.onManageVehicles});

  final VoidCallback onManageVehicles;

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final approved = store.approvedVehicles;
        final selected = store.selectedVehicle;
        final locked = store.isOnline || store.hasActiveAssignment;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose your vehicle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: HiGoTheme.navy,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onManageVehicles,
                  child: const Text(
                    'My Vehicles',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (approved.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HiGoTheme.border),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      color: HiGoTheme.secondaryText,
                      size: 30,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No approved vehicles',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Add a vehicle and wait for approval '
                      'before going online.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: approved.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final vehicle = approved[index];
                    final isSelected = selected?.id == vehicle.id;

                    return _VehicleCard(
                      vehicle: vehicle,
                      selected: isSelected,
                      locked: locked,
                      onTap: () {
                        final success = store.selectVehicle(vehicle.id);

                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Go offline before changing '
                                'your selected vehicle.',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),
            if (selected == null)
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: HiGoTheme.secondaryText,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Select an approved vehicle to go online.',
                      style: TextStyle(
                        fontSize: 11,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock_outline : Icons.check_circle_outline,
                    size: 16,
                    color: HiGoTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${selected.name} · '
                      '${selected.registrationNumber}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HiGoTheme.navy,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final MockDriverVehicle vehicle;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF5F2FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 145,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HiGoTheme.primary : HiGoTheme.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 25,
                    color: selected
                        ? HiGoTheme.primary
                        : HiGoTheme.secondaryText,
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 19,
                      color: HiGoTheme.primary,
                    )
                  else
                    const Icon(
                      Icons.radio_button_unchecked,
                      size: 19,
                      color: HiGoTheme.border,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HiGoTheme.navy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                vehicle.registrationNumber,
                style: const TextStyle(
                  fontSize: 11,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              Text(
                vehicle.category,
                style: const TextStyle(
                  fontSize: 10,
                  color: HiGoTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
