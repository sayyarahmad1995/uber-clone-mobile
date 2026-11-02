import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'widgets/driver_offer_widgets.dart';

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
  final Set<String> _declinedIds = {};
  final ScrollController _scrollController = ScrollController();

  late final List<MockDriverOffer> _mockQueue;
  late int _proposedFarePkr;

  Timer? _timer;
  int _nextMockIndex = 0;
  int _unseenOffers = 0;
  String? _pendingOfferId;
  bool _followingLatest = true;
  bool _touchingList = false;
  bool _selectionPending = false;
  bool _requestAssigned = false;
  _OffersState _state = _OffersState.waiting;

  @override
  void initState() {
    super.initState();
    // Category estimate stands in for the rider's offer until booking is
    // connected to the backend. Changing the offer never changes old bids.
    _proposedFarePkr = widget.rideCategory.estimatedFarePkr ?? 450;
    _mockQueue = mockOffersForFare(_proposedFarePkr);
    _scrollController.addListener(_handleScroll);
    _beginMockTimer();
  }

  void _beginMockTimer() {
    _timer?.cancel();
    if (_nextMockIndex >= _mockQueue.length || _requestAssigned) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _requestAssigned) {
        timer.cancel();
        return;
      }
      if (_selectionPending) return;
      if (_nextMockIndex >= _mockQueue.length) {
        timer.cancel();
        return;
      }
      final offer = _mockQueue[_nextMockIndex++];
      if (!_declinedIds.contains(offer.id)) {
        final follow = _followingLatest && !_touchingList;
        setState(() {
          _offers.add(offer);
          _state = _OffersState.receiving;
          if (!follow && _scrollController.hasClients) _unseenOffers++;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && follow) _scrollToLatest(animated: _offers.length > 1);
        });
      }
      if (_nextMockIndex >= _mockQueue.length) timer.cancel();
    });
  }

  void _restartMockOffers() {
    _timer?.cancel();
    setState(() {
      _offers.clear();
      _declinedIds.clear();
      _nextMockIndex = 0;
      _unseenOffers = 0;
      _pendingOfferId = null;
      _followingLatest = true;
      _state = _OffersState.waiting;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _beginMockTimer();
  }

  void _simulateNoOffers() {
    _timer?.cancel();
    setState(() {
      _offers.clear();
      _nextMockIndex = _mockQueue.length;
      _unseenOffers = 0;
      _followingLatest = true;
      _state = _OffersState.noOffers;
    });
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (_touchingList &&
        position.userScrollDirection == ScrollDirection.forward &&
        _followingLatest) {
      setState(() => _followingLatest = false);
      return;
    }
    if (!_touchingList &&
        position.extentAfter <= 28 &&
        (!_followingLatest || _unseenOffers != 0)) {
      setState(() {
        _followingLatest = true;
        _unseenOffers = 0;
      });
    }
  }

  void _finishTouch() {
    _touchingList = false;
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter <= 28 &&
        (!_followingLatest || _unseenOffers != 0)) {
      setState(() {
        _followingLatest = true;
        _unseenOffers = 0;
      });
    }
  }

  void _scrollToLatest({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final destination = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        destination,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(destination);
    }
  }

  void _revealNewOffers() {
    setState(() {
      _followingLatest = true;
      _unseenOffers = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToLatest();
    });
  }

  void _declineOffer(MockDriverOffer offer, {String message = 'Offer declined'}) {
    final previousOffset =
        _scrollController.hasClients ? _scrollController.offset : null;
    setState(() {
      _declinedIds.add(offer.id);
      _offers.removeWhere((item) => item.id == offer.id);
      if (_unseenOffers > _offers.length) _unseenOffers = _offers.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || previousOffset == null || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      _scrollController.jumpTo(
        previousOffset.clamp(position.minScrollExtent, position.maxScrollExtent).toDouble(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _chooseOffer(MockDriverOffer offer) async {
    if (_selectionPending || _requestAssigned) return;
    _timer?.cancel();
    setState(() {
      _selectionPending = true;
      _pendingOfferId = offer.id;
    });
    final result = await Navigator.of(context).push<DriverConfirmationResult>(
      MaterialPageRoute(
        builder: (_) => DriverConfirmationScreen(
          locations: widget.locations,
          offer: offer,
          rideCategory: widget.rideCategory,
        ),
      ),
    );
    if (!mounted) return;

    setState(() {
      _selectionPending = false;
      _pendingOfferId = null;
      if (result == DriverConfirmationResult.confirmed) {
        _requestAssigned = true;
      }
    });

    if (result == DriverConfirmationResult.declined) {
      _declineOffer(offer, message: 'Driver declined. Choose another offer.');
    } else if (result == DriverConfirmationResult.expired) {
      _declineOffer(
        offer,
        message: 'Driver did not confirm in time. Choose another offer.',
      );
    }
    if (!_requestAssigned && _state != _OffersState.noOffers) {
      _beginMockTimer();
    }
  }

  Future<void> _increaseFare() async {
    final controller = TextEditingController(
      text: (_proposedFarePkr + 50).toString(),
    );
    String? error;
    final newFare = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refreshDialog) => AlertDialog(
          title: const Text('Increase your offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current offer: ${formatOfferFare(_proposedFarePkr)}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'New offer (PKR)',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Earlier driver bids keep their original prices.',
                style: TextStyle(
                  fontSize: 12,
                  color: HiGoTheme.secondaryText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep current offer'),
            ),
            FilledButton(
              onPressed: () {
                final proposed = int.tryParse(controller.text);
                if (proposed == null ||
                    proposed <= _proposedFarePkr ||
                    proposed > 1000000) {
                  refreshDialog(() {
                    error = 'Enter a higher amount up to PKR 1,000,000.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, proposed);
              },
              child: const Text('Increase fare'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || newFare == null) return;
    setState(() => _proposedFarePkr = newFare);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your offer has been increased.')),
    );
  }

  Future<void> _confirmCancellation() async {
    if (_requestAssigned) return;
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel ride request?'),
        content: const Text(
          'Leaving this mock request will discard its available offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep request live'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (!mounted || cancel != true) return;
    _timer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSafetyHelp() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety and help',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Review the driver and vehicle details before choosing. '
                'For an emergency, contact local emergency services.',
              ),
              SizedBox(height: 10),
              Text(
                'This is a booking preview. Live safety support is not connected.',
                style: TextStyle(color: HiGoTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewDetails(MockDriverOffer offer) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.name,
                style: const TextStyle(
                  color: HiGoTheme.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${offer.vehicle} · ${offer.vehicleColor}',
              ),
              const SizedBox(height: 8),
              Text(
                '★ ${offer.rating.toStringAsFixed(1)} '
                '(${offer.reviewCount} reviews)',
              ),
              const SizedBox(height: 8),
              Text('Estimated pickup: ${offer.arrivalMinutes} min'),
              const SizedBox(height: 8),
              Text('Offered fare: ${formatOfferFare(offer.farePkr)}'),
              const SizedBox(height: 8),
              Text(compareDriverFare(offer.farePkr, _proposedFarePkr)),
              const SizedBox(height: 16),
              const Text(
                'Driver profiles and ETAs are demonstration data.',
                style: TextStyle(color: HiGoTheme.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmCancellation();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/welcome_map.png',
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: ColoredBox(color: Color(0x55FFFFFF)),
            ),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    DriverOffersHeader(
                      count: _offers.length,
                      onBack: _confirmCancellation,
                      onHelp: _showSafetyHelp,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildOffersArea()),
                          if (_unseenOffers > 0 && !_followingLatest)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FilledButton.icon(
                                  onPressed: _revealNewOffers,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  label: Text(
                                    '$_unseenOffers new '
                                    '${_unseenOffers == 1 ? 'offer' : 'offers'}',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: HiGoTheme.primary,
                                    minimumSize: const Size(0, 48),
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(0.0, constraints.maxHeight - 140),
                      ),
                      child: DriverOfferBottomSheet(
                        pickup: widget.locations.pickup,
                        destination: widget.locations.destination,
                        proposedFarePkr: _proposedFarePkr,
                        onIncreaseFare: _increaseFare,
                        onCancel: _confirmCancellation,
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

  Widget _buildOffersArea() {
    if (_offers.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_car_outlined,
                color: HiGoTheme.primary,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                _state == _OffersState.waiting
                    ? 'Waiting for driver offers'
                    : 'Waiting for more offers',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your request is still live.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HiGoTheme.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _touchingList = true,
      onPointerUp: (_) => _finishTouch(),
      onPointerCancel: (_) => _finishTouch(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 78),
        itemCount: _offers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return DriverOfferCard(
            key: ValueKey(offer.id),
            offer: offer,
            proposedFarePkr: _proposedFarePkr,
            pending: _pendingOfferId == offer.id,
            enabled: !_selectionPending && !_requestAssigned,
            onDetails: () => _viewDetails(offer),
            onDecline: () => _declineOffer(offer),
            onChoose: () => _chooseOffer(offer),
          );
        },
      ),
    );
  }
}
