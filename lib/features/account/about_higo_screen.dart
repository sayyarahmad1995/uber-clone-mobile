import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';

class AboutHiGoScreen extends StatelessWidget {
  const AboutHiGoScreen({super.key});

  void _showComingLater(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title will be available in a later milestone.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About HiGO',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFF2EDFF), Colors.white, Color(0xFFEDF4FF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.route_outlined,
                      size: 30,
                      color: HiGoTheme.primary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'HiGO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: HiGoTheme.navy,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Move with confidence',
                    style: TextStyle(
                      fontSize: 12,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'A mobility platform designed to connect '
                    'people with convenient transportation '
                    'and mobility services.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: HiGoTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Application',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),

            const SizedBox(height: 10),

            const _AboutInfoTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: '0.1.0+1 · Development',
            ),

            const SizedBox(height: 8),

            const _AboutInfoTile(
              icon: Icons.layers_outlined,
              title: 'Current services',
              subtitle: 'City Ride · Mock implementation',
            ),

            const SizedBox(height: 18),

            const Text(
              'Legal & information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),

            const SizedBox(height: 10),

            _AboutActionTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Document coming later',
              onTap: () => _showComingLater(context, 'Terms of Service'),
            ),

            const SizedBox(height: 8),

            _AboutActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Document coming later',
              onTap: () => _showComingLater(context, 'Privacy Policy'),
            ),

            const SizedBox(height: 8),

            _AboutActionTile(
              icon: Icons.gavel_outlined,
              title: 'Licenses',
              subtitle: 'Open-source software licenses',
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'HiGO',
                  applicationVersion: '0.1.0+1',
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'HiGO is currently under development. '
              'Features, policies, and service availability '
              'may change before production release.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: HiGoTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutInfoTile extends StatelessWidget {
  const _AboutInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _AboutTileContent(icon: icon, title: title, subtitle: subtitle);
  }
}

class _AboutActionTile extends StatelessWidget {
  const _AboutActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: _AboutTileContent(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: const Icon(
            Icons.chevron_right,
            color: HiGoTheme.secondaryText,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _AboutTileContent extends StatelessWidget {
  const _AboutTileContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F0FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: HiGoTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HiGoTheme.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
