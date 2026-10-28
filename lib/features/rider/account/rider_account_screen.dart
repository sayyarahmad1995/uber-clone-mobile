import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../../account/widgets/higo_account_tile.dart';
import 'become_driver_screen.dart';

class RiderAccountScreen extends StatelessWidget {
  const RiderAccountScreen({super.key});

  void _comingLater(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available later.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: Container(
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
                onTap: () => _comingLater(context, 'Profile editing'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HiGoTheme.border),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
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
                      SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ali',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Rider · Demo profile',
                              style: TextStyle(
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
              subtitle: 'Your profile and contact details',
              onTap: () => _comingLater(context, 'Personal information'),
            ),
            const SizedBox(height: 10),
            HiGoAccountTile(
              icon: Icons.bookmark_border,
              title: 'Saved Places',
              subtitle: 'Home, work, and favorite locations',
              onTap: () => _comingLater(context, 'Saved places'),
            ),
            const SizedBox(height: 20),
            Material(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BecomeDriverScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCD6FF)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.directions_car,
                          color: HiGoTheme.primary,
                          size: 25,
                        ),
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Become a Driver',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Apply to drive with HiGO',
                              style: TextStyle(
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
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'App preferences',
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
      ),
    );
  }
}
