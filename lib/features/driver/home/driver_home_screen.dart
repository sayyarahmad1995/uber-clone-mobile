import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import 'widgets/availability_slider.dart';
import '../bidding/ride_requests_screen.dart';
import '../bidding/active_bids_screen.dart';
import '../trip/driver_assignment_navigation.dart';
import '../../../shared/widgets/higo_home_header.dart';
import 'widgets/approved_vehicle_selector.dart';
import '../vehicles/my_vehicles_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key, required this.onAccountTap});

  final VoidCallback onAccountTap;

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _showMapHeader = true;

  bool _onPanelNotification(DraggableScrollableNotification notification) {
    final shouldShow = notification.extent < 0.78;

    if (shouldShow != _showMapHeader) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _showMapHeader == shouldShow) {
          return;
        }

        setState(() {
          _showMapHeader = shouldShow;
        });
      });
    }

    return false;
  }

  Future<void> _showRequest(
    BuildContext context,
    MockRideRequest request,
  ) async {
    final store = DriverDemoStore.instance;

    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _RequestBidSheet(request: request),
    );

    if (amount == null || !context.mounted) return;

    store.submitBid(request.id, amount);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo bid submitted locally. No API request sent.'),
      ),
    );
  }

  Future<void> _showRequestCluster(
    BuildContext context,
    List<MockRideRequest> requests,
  ) async {
    final selected = await showModalBottomSheet<MockRideRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.65,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nearby ride requests',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: HiGoTheme.navy,
                          ),
                        ),
                      ),
                      Text(
                        '${requests.length} requests',
                        style: const TextStyle(
                          fontSize: 12,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(sheetContext, request);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: HiGoTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request.category,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: HiGoTheme.navy,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Rs ${request.estimatedFarePkr}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: HiGoTheme.primary,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: HiGoTheme.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'From: ${request.pickup}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'To: ${request.destination}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  '${request.distanceKm} km · '
                                  '${request.durationMinutes} min',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: HiGoTheme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await _showRequest(context, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = DriverDemoStore.instance;

    return Scaffold(
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/welcome_map.png',
                  fit: BoxFit.cover,
                ),
              ),

              // Mock driver position.
              const Align(
                alignment: Alignment(0, -0.20),
                child: _DriverLocationMarker(),
              ),

              // Incoming request bubbles.
              if (store.isOnline)
                Positioned(
                  top: 85,
                  left: 0,
                  right: 0,
                  height: MediaQuery.sizeOf(context).height * 0.52,
                  child: _RequestMapLayer(
                    requests: store.availableRequests,
                    onRequestTap: (request) {
                      _showRequest(context, request);
                    },
                    onClusterTap: (requests) {
                      _showRequestCluster(context, requests);
                    },
                  ),
                ),

              // Top map controls.
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: HiGoHomeHeader(
                    firstName: 'Ahmed',
                    showMapControls: _showMapHeader,
                    onAccountTap: widget.onAccountTap,
                    onNotifications: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Driver notifications coming later.'),
                        ),
                      );
                    },
                    onRecenter: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Recenter requires the interactive map.',
                          ),
                        ),
                      );
                    },
                    onNorthUp: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'North-up requires the interactive map.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom availability panel.
              NotificationListener<DraggableScrollableNotification>(
                onNotification: _onPanelNotification,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.08,
                  minChildSize: 0.08,
                  maxChildSize: 0.80,
                  snap: true,
                  snapSizes: const [0.52],
                  expand: true,
                  builder: (context, scrollController) {
                    return Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x19000000),
                            blurRadius: 22,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: HiGoTheme.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 15,
                                color: store.isOnline
                                    ? const Color(0xFF0A9953)
                                    : const Color(0xFFA3A9C1),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  store.isOnline
                                      ? 'You are online'
                                      : 'You are offline',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (store.hasActiveAssignment) ...[
                            const SizedBox(height: 14),
                            Material(
                              color: const Color(0xFFF0EDFF),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => openDriverAssignment(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_car,
                                        color: HiGoTheme.primary,
                                        size: 25,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Current assignment',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: HiGoTheme.navy,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              store
                                                      .assignmentStage(
                                                        store
                                                            .activeAssignmentId!,
                                                      )
                                                      ?.label ??
                                                  'Continue trip',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: HiGoTheme.secondaryText,
                                              ),
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
                          ],

                          const SizedBox(height: 6),

                          Padding(
                            padding: const EdgeInsets.only(left: 27),
                            child: Text(
                              store.isOnline
                                  ? 'Ready to receive ride requests.'
                                  : 'Go online to start receiving '
                                        'ride requests.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: HiGoTheme.secondaryText,
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          ApprovedVehicleSelector(
                            onManageVehicles: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MyVehiclesScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          AvailabilitySlider(
                            isOnline: store.isOnline,
                            onChanged: store.setOnline,
                          ),

                          const SizedBox(height: 24),

                          const Divider(height: 1),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: _HomeStat(
                                  icon: Icons.inbox_outlined,
                                  value: store.isOnline
                                      ? '${store.availableRequests.length}'
                                      : '0',
                                  label: 'Requests',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RideRequestsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: _HomeStat(
                                  icon: Icons.local_offer_outlined,
                                  value: '${store.activeBids.length}',
                                  label: 'Active bids',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ActiveBidsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const Expanded(
                                child: _HomeStat(
                                  icon: Icons.bar_chart_rounded,
                                  value: '0',
                                  label: 'Trips today',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RequestBubble extends StatelessWidget {
  const _RequestBubble({required this.request, required this.onTap});

  final MockRideRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 115, maxWidth: 142),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rs ${request.estimatedFarePkr}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HiGoTheme.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request.distanceKm} km · '
                  '${request.durationMinutes} min',
                  style: const TextStyle(
                    fontSize: 11,
                    color: HiGoTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 13,
                      color: HiGoTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.pickup.split(',').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: HiGoTheme.navy,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: HiGoTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestBidSheet extends StatefulWidget {
  const _RequestBidSheet({required this.request});

  final MockRideRequest request;

  @override
  State<_RequestBidSheet> createState() => _RequestBidSheetState();
}

class _RequestBidSheetState extends State<_RequestBidSheet> {
  late final TextEditingController _fareController;

  @override
  void initState() {
    super.initState();

    _fareController = TextEditingController(
      text: widget.request.estimatedFarePkr.toString(),
    );
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  void _changeFare(int delta) {
    final amount = int.tryParse(_fareController.text.trim()) ?? 0;

    final updated = amount + delta;

    _fareController.text = (updated < 1 ? 1 : updated).toString();
  }

  void _submitBid() {
    final amount = int.tryParse(_fareController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid bid amount.')),
      );
      return;
    }

    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        6,
        22,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Trip details',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'City Ride · ${request.category}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HiGoTheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TripDetailRow(
                      icon: Icons.radio_button_checked,
                      label: 'Pickup',
                      value: request.pickup,
                    ),
                    const SizedBox(height: 16),
                    _TripDetailRow(
                      icon: Icons.location_on,
                      label: 'Destination',
                      value: request.destination,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: HiGoTheme.secondaryText,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text('${request.durationMinutes} min'),
                        const SizedBox(width: 22),
                        const Icon(
                          Icons.route,
                          color: HiGoTheme.secondaryText,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text('${request.distanceKm} km'),
                      ],
                    ),

                    const Divider(height: 32),

                    const Text(
                      'Reference estimate · Demo',
                      style: TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Rs ${request.estimatedFarePkr}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Your bid (PKR)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: () => _changeFare(-50),
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _fareController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Amount',
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.outlined(
                          onPressed: () => _changeFare(50),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: _submitBid,
              child: const Text('Submit Bid'),
            ),

            const SizedBox(height: 6),

            const Text(
              'UI demo only · No bid sent to the API',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: HiGoTheme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripDetailRow extends StatelessWidget {
  const _TripDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: HiGoTheme.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HiGoTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverLocationMarker extends StatelessWidget {
  const _DriverLocationMarker();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(radius: 49, backgroundColor: Color(0x335038F5)),
        CircleAvatar(radius: 31, backgroundColor: Color(0x445038F5)),
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.white,
          child: CircleAvatar(radius: 8, backgroundColor: HiGoTheme.primary),
        ),
      ],
    );
  }
}

class _HomeStat extends StatelessWidget {
  const _HomeStat({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Icon(icon, size: 19, color: HiGoTheme.primary),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: HiGoTheme.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestMapLayer extends StatelessWidget {
  const _RequestMapLayer({
    required this.requests,
    required this.onRequestTap,
    required this.onClusterTap,
  });

  final List<MockRideRequest> requests;
  final ValueChanged<MockRideRequest> onRequestTap;
  final ValueChanged<List<MockRideRequest>> onClusterTap;

  // Mock positions only. Replace with real map projection
  // when geographic coordinates become available.
  Offset _mockPosition(String id) {
    const known = <String, Offset>{
      'request_001': Offset(0.20, 0.30),
      'request_002': Offset(0.28, 0.34),
      'request_003': Offset(0.78, 0.67),
    };

    if (known.containsKey(id)) {
      return known[id]!;
    }

    // Deterministic fallback: the same ID gets the
    // same mock position, regardless of list ordering.
    var hash = 0;

    for (final code in id.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }

    return Offset(
      0.10 + (hash % 800) / 1000,
      0.10 + ((hash ~/ 800) % 800) / 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (requests.isEmpty) {
          return const SizedBox.shrink();
        }

        // Reserve enough horizontal space for a bubble.
        final usableWidth = (constraints.maxWidth - 152.0)
            .clamp(0.0, double.infinity)
            .toDouble();

        final usableHeight = (constraints.maxHeight - 110.0)
            .clamp(0.0, double.infinity)
            .toDouble();

        final centers = <Offset>[
          for (final request in requests)
            Offset(
              76.0 + usableWidth * _mockPosition(request.id).dx,
              55.0 + usableHeight * _mockPosition(request.id).dy,
            ),
        ];

        // Two bubbles are considered overlapping when
        // their approximate display rectangles intersect.
        bool overlaps(int a, int b) {
          return (centers[a].dx - centers[b].dx).abs() < 150.0 &&
              (centers[a].dy - centers[b].dy).abs() < 95.0;
        }

        // Connected-component clustering:
        // A overlaps B and B overlaps C => one cluster.
        final visited = List<bool>.filled(requests.length, false);

        final groups = <List<int>>[];

        for (var start = 0; start < requests.length; start++) {
          if (visited[start]) continue;

          final members = <int>[start];
          visited[start] = true;

          for (var cursor = 0; cursor < members.length; cursor++) {
            final current = members[cursor];

            for (var candidate = 0; candidate < requests.length; candidate++) {
              if (visited[candidate]) continue;

              if (overlaps(current, candidate)) {
                visited[candidate] = true;
                members.add(candidate);
              }
            }
          }

          groups.add(members);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final members in groups)
              if (members.length == 1)
                Positioned(
                  left: centers[members.first].dx - 71,
                  top: centers[members.first].dy - 45,
                  child: _RequestBubble(
                    request: requests[members.first],
                    onTap: () => onRequestTap(requests[members.first]),
                  ),
                )
              else
                Positioned(
                  left: _centerOf(centers, members).dx - 27,
                  top: _centerOf(centers, members).dy - 27,
                  child: _RequestClusterMarker(
                    count: members.length,
                    onTap: () {
                      onClusterTap([
                        for (final index in members) requests[index],
                      ]);
                    },
                  ),
                ),
          ],
        );
      },
    );
  }

  Offset _centerOf(List<Offset> centers, List<int> members) {
    var x = 0.0;
    var y = 0.0;

    for (final index in members) {
      x += centers[index].dx;
      y += centers[index].dy;
    }

    return Offset(x / members.length, y / members.length);
  }
}

class _RequestClusterMarker extends StatelessWidget {
  const _RequestClusterMarker({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$count nearby ride requests',
      child: Material(
        color: const Color(0x335036F5),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: HiGoTheme.primary,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
