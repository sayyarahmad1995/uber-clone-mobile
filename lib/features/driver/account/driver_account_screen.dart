import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../../account/widgets/higo_account_tile.dart';
import '../models/mock_ride_request.dart';
import '../vehicles/my_vehicles_screen.dart';
import '../../../app/app_mode_controller.dart';

class DriverAccountScreen extends StatelessWidget {
  const DriverAccountScreen({super.key});

  void _comingLater(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available later.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _comingLater(context, 'Driver profile'),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HiGoTheme.border),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFFEFECFF),
                            child: Text(
                              'A',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ahmed',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Driver · Demo profile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: store.isOnline
                                          ? const Color(0xFF159653)
                                          : HiGoTheme.secondaryText,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      store.isOnline
                                          ? 'Online · Demo'
                                          : 'Offline · Demo',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: HiGoTheme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: HiGoTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Placeholder vehicle card.
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _comingLater(context, 'Vehicle details'),
                    child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HiGoTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFFEFECFF),
                            child: Icon(
                              Icons.directions_car,
                              color: HiGoTheme.primary,
                              size: 27,
                            ),
                          ),
                          SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Vehicle',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  store.selectedVehicle == null
                                      ? 'No vehicle selected'
                                      : '${store.selectedVehicle!.name} · '
                                            '${store.selectedVehicle!.registrationNumber}',
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
                          Icon(Icons.chevron_right, color: HiGoTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                HiGoAccountTile(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Name and contact details',
                  onTap: () => _comingLater(context, 'Personal information'),
                ),
                const SizedBox(height: 10),
                HiGoAccountTile(
                  icon: Icons.directions_car_outlined,
                  title: 'My Vehicles',
                  subtitle: 'Manage vehicles and approval status',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyVehiclesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                HiGoAccountTile(
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  subtitle: 'Driver and vehicle documents',
                  onTap: () => _comingLater(context, 'Documents'),
                ),
                const SizedBox(height: 20),
                HiGoAccountTile(
                  icon: Icons.swap_horiz,
                  title: 'Switch to Rider',
                  subtitle: 'Use the rider interface',
                  onTap: switchToRiderMode,
                ),
                const SizedBox(height: 10),
                HiGoAccountTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'App preferences and notifications',
                  onTap: () => _comingLater(context, 'Settings'),
                ),
                const SizedBox(height: 10),
                HiGoAccountTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help or contact us',
                  onTap: () => _comingLater(context, 'Help & Support'),
                ),
                const SizedBox(height: 10),
                HiGoAccountTile(
                  icon: Icons.info_outline,
                  title: 'About HiGO',
                  subtitle: 'App information and legal details',
                  onTap: () => _comingLater(context, 'About HiGO'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
