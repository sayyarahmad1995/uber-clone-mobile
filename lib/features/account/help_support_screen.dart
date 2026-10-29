import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showContactMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Support requests will be available '
          'in a later milestone.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    color: HiGoTheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Find answers to common questions '
                          'about using HiGO.',
                          style: TextStyle(
                            fontSize: 12,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Frequently asked questions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),

            const SizedBox(height: 10),

            const _HelpQuestion(
              title: 'How do I book a ride?',
              answer:
                  'Open Rider Home, choose your pickup and '
                  'destination, review the route, and continue '
                  'through the ride selection process.',
            ),
            const SizedBox(height: 8),

            const _HelpQuestion(
              title: 'How do I manage saved places?',
              answer:
                  'Open Rider Account and select Saved Places. '
                  'You can add, edit, or remove Home, Work, '
                  'and custom locations.',
            ),
            const SizedBox(height: 8),

            const _HelpQuestion(
              title:
                  'How do I switch between Rider '
                  'and Driver modes?',
              answer:
                  'Open Account and select Switch to Driver '
                  'or Switch to Rider. This switching feature '
                  'is currently available for development. '
                  'Driver access will require approval '
                  'in the production app.',
            ),
            const SizedBox(height: 8),

            const _HelpQuestion(
              title: 'How do I change notification settings?',
              answer:
                  'Open Account, then Settings. You can '
                  'change your mock notification preferences. '
                  'These settings are not connected to '
                  'real notifications yet.',
            ),
            const SizedBox(height: 8),

            const _HelpQuestion(
              title: 'How do I become a HiGO driver?',
              answer:
                  'Open Rider Account and select Become '
                  'a Driver. The application process '
                  'will be implemented in a later milestone.',
            ),

            const SizedBox(height: 20),

            const Text(
              'Need more help?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),

            const SizedBox(height: 10),

            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _showContactMessage(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HiGoTheme.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: HiGoTheme.primary,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Support',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HiGoTheme.navy,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Support messaging coming soon',
                              style: TextStyle(
                                fontSize: 11,
                                color: HiGoTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: HiGoTheme.secondaryText,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'This help center contains demonstration '
              'content. No support request is submitted.',
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

class _HelpQuestion extends StatelessWidget {
  const _HelpQuestion({required this.title, required this.answer});

  final String title;
  final String answer;

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
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            iconColor: HiGoTheme.primary,
            collapsedIconColor: HiGoTheme.secondaryText,
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HiGoTheme.navy,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
