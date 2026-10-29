import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../../../shared/widgets/higo_home_header.dart';
import '../account/rider_account_screen.dart';
import '../payments/rider_payments_screen.dart';
import '../rides/rider_rides_screen.dart';
import 'rider_home_screen.dart';
import '../account/rider_profile_store.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _selectedIndex = 0;

  bool _showMapHeader = true;

  bool _onPanelNotification(DraggableScrollableNotification notification) {
    // The current Rider Home maximum extent is 0.80.
    final shouldShow = notification.extent < 0.78;

    if (shouldShow != _showMapHeader) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _showMapHeader == shouldShow) return;

        setState(() {
          _showMapHeader = shouldShow;
        });
      });
    }

    return false;
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showDemoMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Stack(
            children: [
              NotificationListener<DraggableScrollableNotification>(
                onNotification: _onPanelNotification,
                child: const RiderHomeScreen(),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AnimatedBuilder(
                      animation: riderProfileStore,
                      builder: (context, _) {
                        return HiGoHomeHeader(
                          firstName: riderProfileStore.profile.firstName,
                          showMapControls: _showMapHeader,
                          onAccountTap: () => _selectTab(3),
                          onNotifications: () {
                            _showDemoMessage(
                              'Rider notifications coming later.',
                            );
                          },
                          onRecenter: () {
                            _showDemoMessage(
                              'Recenter will be available '
                              'with the interactive map.',
                            );
                          },
                          onNorthUp: () {
                            _showDemoMessage(
                              'North-up will be available '
                              'with the interactive map.',
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const RiderRidesScreen(),
          const RiderPaymentsScreen(),
          const RiderAccountScreen(),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: HiGoTheme.primary),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: HiGoTheme.primary,
            ),
            label: 'Payments',
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
