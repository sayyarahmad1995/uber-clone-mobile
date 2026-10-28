import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_driver_vehicle.dart';
import '../models/mock_ride_request.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatelessWidget {
  const MyVehiclesScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Vehicles',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final vehicles = store.vehicles;
          final selectedId = store.selectedVehicleId;
          final selectionLocked = store.isOnline || store.hasActiveAssignment;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFF2EDFF),
                  Colors.white,
                  Colors.white,
                  Color(0xFFEDF4FF),
                ],
                stops: [0, 0.26, 0.72, 1],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registered vehicles',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage vehicles and review their status.',
                            style: TextStyle(
                              fontSize: 12,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 92,
                      height: 40,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          fixedSize: const Size(92, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddVehicleScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text('Add'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (vehicles.isEmpty)
                  const _EmptyVehiclesState()
                else
                  for (final vehicle in vehicles) ...[
                    _VehicleListCard(
                      vehicle: vehicle,
                      selected: selectedId == vehicle.id,
                      selectionLocked: selectionLocked,
                      onSelect: () {
                        final success = store.selectVehicle(vehicle.id);

                        _showMessage(
                          context,
                          success
                              ? '${vehicle.name} selected.'
                              : 'Go offline and finish any active '
                                    'assignment before changing vehicles.',
                        );
                      },
                    ),
                    const SizedBox(height: 11),
                  ],

                const SizedBox(height: 12),
                const Text(
                  'Only approved vehicles can be selected for '
                  'going online. Approval statuses shown here '
                  'are mock data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: HiGoTheme.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VehicleListCard extends StatelessWidget {
  const _VehicleListCard({
    required this.vehicle,
    required this.selected,
    required this.selectionLocked,
    required this.onSelect,
  });

  final MockDriverVehicle vehicle;
  final bool selected;
  final bool selectionLocked;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final approved = vehicle.isApproved;

    final (
      statusLabel,
      statusColor,
      statusBackground,
    ) = switch (vehicle.approvalStatus) {
      MockVehicleApprovalStatus.approved => (
        'Approved',
        const Color(0xFF15803D),
        const Color(0xFFE9F8EF),
      ),
      MockVehicleApprovalStatus.pending => (
        'Pending',
        const Color(0xFF9A6400),
        const Color(0xFFFFF4DA),
      ),
      MockVehicleApprovalStatus.rejected => (
        'Rejected',
        const Color(0xFFC03939),
        const Color(0xFFFFEAEA),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? HiGoTheme.primary : HiGoTheme.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  size: 27,
                  color: HiGoTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vehicle.registrationNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vehicle.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (selected)
            const Row(
              children: [
                Icon(Icons.check_circle, color: HiGoTheme.primary, size: 19),
                SizedBox(width: 7),
                Text(
                  'Selected vehicle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HiGoTheme.primary,
                  ),
                ),
              ],
            )
          else if (approved)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: selectionLocked ? null : onSelect,
                child: Text(
                  selectionLocked
                      ? 'Unavailable while online'
                      : 'Select vehicle',
                ),
              ),
            )
          else
            Text(
              vehicle.approvalStatus == MockVehicleApprovalStatus.pending
                  ? 'Awaiting approval'
                  : 'Not eligible for selection',
              style: const TextStyle(
                fontSize: 12,
                color: HiGoTheme.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyVehiclesState extends StatelessWidget {
  const _EmptyVehiclesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 40,
            color: HiGoTheme.secondaryText,
          ),
          SizedBox(height: 12),
          Text(
            'No vehicles registered',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: HiGoTheme.navy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add your first vehicle to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: HiGoTheme.secondaryText),
          ),
        ],
      ),
    );
  }
}
