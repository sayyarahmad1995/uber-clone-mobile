import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import 'driver_confirmation_screen.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'ride_category.dart';

enum _OffersState { waiting, receiving, noOffers }

class DriverOffersScreen extends StatefulWidget {
  const DriverOffersScreen({
    super.key,
    required this.locations,
    required this.rideCategory,
  });

  final SelectedLocations locations;
  final RideCategory rideCategory;

  @override
  State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen> {
  final List<MockDriverOffer> _offers = [];

  Timer? _timer;
  String? _selectedOfferId;
  _OffersState _state = _OffersState.waiting;

  @override
  void initState() {
    super.initState();
    _startMockBidding();
  }

  void _startMockBidding() {
    _timer?.cancel();
    _offers.clear();
    _selectedOfferId = null;
    _state = _OffersState.waiting;

    var index = 0;

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (index >= mockDriverOffers.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _offers.add(mockDriverOffers[index]);
        _state = _OffersState.receiving;
      });

      index++;

      if (index >= mockDriverOffers.length) {
        timer.cancel();
      }
    });
  }

  void _retry() {
    setState(_startMockBidding);
  }

  void _simulateNoOffers() {
    _timer?.cancel();

    setState(() {
      _offers.clear();
      _selectedOfferId = null;
      _state = _OffersState.noOffers;
    });
  }

  void _returnHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmCancellation() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel ride request?'),
        content: const Text(
          'Your simulated request and offers '
          'will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Waiting'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (!mounted || cancel != true) return;

    _timer?.cancel();
    _returnHome();
  }

  MockDriverOffer? get _selectedOffer {
    for (final offer in _offers) {
      if (offer.id == _selectedOfferId) {
        return offer;
      }
    }
    return null;
  }

  void _selectDriver() {
    final offer = _selectedOffer;
    if (offer == null) return;

    _timer?.cancel();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverConfirmationScreen(
          locations: widget.locations,
          offer: offer,
          rideCategory: widget.rideCategory,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOffer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmCancellation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Driver offers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFF3EEFF),
          leading: IconButton(
            onPressed: _confirmCancellation,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Demo controls',
              onSelected: (value) {
                if (value == 'no_offers') {
                  _simulateNoOffers();
                } else if (value == 'retry') {
                  _retry();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'no_offers',
                  child: Text('Demo: No offers'),
                ),
                PopupMenuItem(
                  value: 'retry',
                  child: Text('Demo: Restart bids'),
                ),
              ],
            ),
          ],
        ),

        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: [0, 0.3, 0.75, 1],
                    colors: [
                      Color(0xFFF1EBFF),
                      Colors.white,
                      Colors.white,
                      Color(0xFFE8F3FF),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Finding your driver',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: HiGoTheme.navy,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'City Ride · ${widget.rideCategory.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HiGoTheme.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${widget.locations.pickup} → '
                      '${widget.locations.destination}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (_state == _OffersState.waiting ||
                        (_state == _OffersState.receiving &&
                            _timer?.isActive == true))
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: HiGoTheme.primary,
                      ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Driver offers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: HiGoTheme.navy,
                            ),
                          ),
                        ),
                        Text(
                          '${_offers.length} received',
                          style: const TextStyle(
                            fontSize: 12,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: _state == _OffersState.noOffers
                          ? _NoOffersView(
                              onRetry: _retry,
                              onReturnHome: _returnHome,
                            )
                          : _offers.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 42,
                                    color: HiGoTheme.primary,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Waiting for driver offers...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: HiGoTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _offers.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final offer = _offers[index];

                                return _OfferCard(
                                  offer: offer,
                                  selected: offer.id == _selectedOfferId,
                                  onTap: () {
                                    setState(() {
                                      _selectedOfferId = offer.id;
                                    });
                                  },
                                );
                              },
                            ),
                    ),

                    if (_state != _OffersState.noOffers) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: selected == null ? null : _selectDriver,
                        child: const Text('Select Driver'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _confirmCancellation,
                        child: const Text('Cancel Request'),
                      ),
                    ],

                    const SizedBox(height: 6),

                    const Text(
                      'Demo only · No real drivers connected',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoOffersView extends StatelessWidget {
  const _NoOffersView({required this.onRetry, required this.onReturnHome});

  final VoidCallback onRetry;
  final VoidCallback onReturnHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 52,
            color: HiGoTheme.secondaryText,
          ),
          const SizedBox(height: 16),
          const Text(
            'No offers yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: HiGoTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No drivers responded in this demo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: HiGoTheme.secondaryText),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          const SizedBox(height: 8),
          TextButton(onPressed: onReturnHome, child: const Text('Return Home')),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final MockDriverOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HiGoTheme.primary : HiGoTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 23,
                backgroundColor: Color(0xFFF0EDFF),
                child: Icon(Icons.person_outline, color: HiGoTheme.primary),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.vehicle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFEDA72B),
                        ),
                        Flexible(
                          child: Text(
                            ' ${offer.rating.toStringAsFixed(1)}'
                            ' · ${offer.arrivalMinutes} min away',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${offer.farePkr}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: HiGoTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 21,
                    color: selected ? HiGoTheme.primary : HiGoTheme.border,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
