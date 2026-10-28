import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';

class RiderPaymentsScreen extends StatelessWidget {
  const RiderPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HiGoTheme.border),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFEFECFF),
                  child: Icon(
                    Icons.payments_outlined,
                    color: HiGoTheme.primary,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Payment methods and receipts',
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
          const SizedBox(height: 28),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 42,
                  color: HiGoTheme.primary,
                ),
                SizedBox(height: 14),
                Text(
                  'No payment history yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HiGoTheme.navy,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Payment records will appear here.',
                  style: TextStyle(
                    fontSize: 13,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
