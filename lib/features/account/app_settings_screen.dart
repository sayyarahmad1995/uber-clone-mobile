import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';
import 'app_settings_store.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFF2EDFF), Colors.white, Color(0xFFEDF4FF)],
          ),
        ),
        child: AnimatedBuilder(
          animation: appSettingsStore,
          builder: (context, _) {
            final settings = appSettingsStore.settings;

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HiGoTheme.navy,
                  ),
                ),
                const SizedBox(height: 10),

                _SettingsSwitch(
                  icon: Icons.notifications_outlined,
                  title: 'Push notifications',
                  subtitle: 'Enable app notifications',
                  value: settings.pushNotifications,
                  onChanged: appSettingsStore.setPushNotifications,
                ),

                const SizedBox(height: 8),

                _SettingsSwitch(
                  icon: Icons.route_outlined,
                  title: 'Trip updates',
                  subtitle: 'Ride and delivery status updates',
                  value: settings.tripUpdates,
                  onChanged: settings.pushNotifications
                      ? appSettingsStore.setTripUpdates
                      : null,
                ),

                const SizedBox(height: 8),

                _SettingsSwitch(
                  icon: Icons.campaign_outlined,
                  title: 'Offers and promotions',
                  subtitle: 'News and promotional messages',
                  value: settings.promotionalNotifications,
                  onChanged: settings.pushNotifications
                      ? appSettingsStore.setPromotionalNotifications
                      : null,
                ),

                const SizedBox(height: 20),

                const Text(
                  'About these settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HiGoTheme.navy,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Your preferences are stored temporarily '
                  'for development. They are shared between '
                  'Rider and Driver modes and reset when '
                  'the app restarts.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HiGoTheme.border),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: HiGoTheme.primary,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: HiGoTheme.primary, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HiGoTheme.navy,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: HiGoTheme.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
