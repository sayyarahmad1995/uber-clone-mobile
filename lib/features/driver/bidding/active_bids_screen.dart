import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'submit_bid_screen.dart';
import '../trip/driver_trip_in_progress_screen.dart';
import '../trip/driver_assignment_navigation.dart';

class ActiveBidsScreen extends StatelessWidget {
  const ActiveBidsScreen({super.key});

  Future<void> _withdraw(BuildContext context, MockDriverBid bid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw bid?'),
        content: const Text(
          'This will remove the bid from the '
          'local demo list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Bid'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      DriverDemoStore.instance.withdrawBid(bid.requestId);
    }
  }

  void _simulateSelection(BuildContext context, MockDriverBid bid) {
    final store = DriverDemoStore.instance;

    final selected = store.selectDemoBid(bid.requestId);

    if (!selected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finish the current demo assignment '
            'before selecting another rider bid.',
          ),
        ),
      );
      return;
    }

    openDriverAssignment(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My active bids',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0, 0.3, 0.7, 1],
                  colors: [
                    Color(0xFFF1EBFF),
                    Colors.white,
                    Colors.white,
                    Color(0xFFEAF3FF),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final bids = store.activeBids;

              if (bids.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gavel_outlined,
                          size: 42,
                          color: HiGoTheme.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No active bids',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Go online and submit a mock bid '
                          'to see it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: HiGoTheme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                itemCount: bids.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  final request = store.requestFor(bid.requestId);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HiGoTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.category,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: HiGoTheme.navy,
                                ),
                              ),
                            ),
                            Text(
                              bid.selectedByRider
                                  ? 'Selected · Demo'
                                  : 'Waiting · Demo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: bid.selectedByRider
                                    ? const Color(0xFF16854D)
                                    : const Color(0xFFB47718),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          request.pickup,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: HiGoTheme.secondaryText,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.destination,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const Divider(height: 28),
                        Row(
                          children: [
                            const Text(
                              'My bid',
                              style: TextStyle(color: HiGoTheme.secondaryText),
                            ),
                            const Spacer(),
                            Text(
                              'Rs ${bid.farePkr}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: HiGoTheme.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (!bid.selectedByRider) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubmitBidScreen(
                                          request: request,
                                          existingBidPkr: bid.farePkr,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Edit Bid'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _withdraw(context, bid),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFB42335),
                                  ),
                                  child: const Text('Withdraw'),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: store.hasActiveAssignment
                                ? null
                                : () => _simulateSelection(context, bid),
                            child: const Text('Demo: Rider Selects Bid'),
                          ),
                        ] else if (store.isTripInProgress(bid.requestId)) ...[
                          const Text(
                            'Trip in progress · Demo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HiGoTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DriverTripInProgressScreen(
                                    request: request,
                                    bid: bid,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Return to Trip'),
                          ),
                        ] else ...[
                          Text(
                            store.assignmentStage(bid.requestId)?.label ??
                                'Assignment selected · Demo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: HiGoTheme.secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              openDriverAssignment(context);
                            },
                            child: const Text('Continue Assignment'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
