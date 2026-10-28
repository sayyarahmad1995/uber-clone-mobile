import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';

class BecomeDriverScreen extends StatelessWidget {
  const BecomeDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Become a Driver',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDFF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.directions_car_outlined,
                                size: 43,
                                color: HiGoTheme.primary,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Drive with HiGO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Apply to join HiGO as a driver '
                              'while keeping your rider account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: HiGoTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Driver application',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _InfoRow(
                        icon: Icons.person_outline,
                        title: 'Personal information',
                        subtitle: 'Driver identity and contact details',
                      ),
                      const SizedBox(height: 12),
                      const _InfoRow(
                        icon: Icons.directions_car_outlined,
                        title: 'Vehicle information',
                        subtitle: 'Details relevant to your vehicle',
                      ),
                      const SizedBox(height: 12),
                      const _InfoRow(
                        icon: Icons.description_outlined,
                        title: 'Documents',
                        subtitle:
                            'Required documents will be shown '
                            'in the application flow',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Application requirements, review stages, '
                        'and eligibility will follow the existing '
                        'HiGO backend rules.',
                        style: TextStyle(
                          fontSize: 12,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Driver applications will be '
                        'implemented in a later milestone.',
                      ),
                    ),
                  );
                },
                child: const Text('Application Coming Soon'),
              ),
              const SizedBox(height: 7),
              const Text(
                'No application will be submitted in this demo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: HiGoTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: HiGoTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: HiGoTheme.navy,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
