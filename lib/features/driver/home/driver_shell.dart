import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../account/driver_account_screen.dart';
import '../activity/driver_activity_screen.dart';
import '../bidding/active_bids_screen.dart';
import 'driver_home_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DriverHomeScreen(onAccountTap: () => _selectTab(3)),
          const ActiveBidsScreen(),
          const DriverActivityScreen(),
          const DriverAccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEFECFF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: HiGoTheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: HiGoTheme.primary),
            label: 'Active Bids',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(
              Icons.access_time_filled,
              color: HiGoTheme.primary,
            ),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: HiGoTheme.primary),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
