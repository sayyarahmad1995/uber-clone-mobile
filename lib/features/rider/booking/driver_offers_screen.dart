import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'widgets/driver_offer_widgets.dart';
import 'widgets/nearby_drivers_mock_map.dart';

import '../../../app/higo_theme.dart';
import 'driver_confirmation_screen.dart';
import 'location_selection_screen.dart';
import 'mock_driver_offer.dart';
import 'ride_category.dart';

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
  bool _interactionPaused = false;
  bool _selectionPending = false;
  bool _requestAssigned = false;
  bool _allowLeave = false;

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
        final follow = _followingLatest && !_touchingList && !_interactionPaused;
        setState(() {
          _offers.add(offer);
          if (!follow && _scrollController.hasClients) {
            _unseenOffers++;
            _followingLatest = false;
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && follow) _scrollToLatest(animated: _offers.length > 1);
        });
      }
      if (_nextMockIndex >= _mockQueue.length) timer.cancel();
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
    if (!_requestAssigned) {
      _beginMockTimer();
    }
  }

  Future<void> _increaseFare() async {
    setState(() => _interactionPaused = true);
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
    if (!mounted) return;
    setState(() => _interactionPaused = false);
    if (newFare == null) return;
    setState(() => _proposedFarePkr = newFare);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your offer has been increased.')),
    );
  }

  Future<void> _confirmCancellation() async {
    if (_requestAssigned) {
      _leaveToHome();
      return;
    }
    setState(() => _interactionPaused = true);
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
    if (!mounted) return;
    setState(() => _interactionPaused = false);
    if (cancel != true) return;
    _leaveToHome();
  }

  void _leaveToHome() {
    _timer?.cancel();
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  Future<void> _showSafetyHelp() async {
    setState(() => _interactionPaused = true);
    await showModalBottomSheet<void>(
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
    if (mounted) setState(() => _interactionPaused = false);
  }

  Future<void> _viewDetails(MockDriverOffer offer) async {
    setState(() => _interactionPaused = true);
    await showModalBottomSheet<void>(
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
    if (mounted) setState(() => _interactionPaused = false);
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: _allowLeave,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_allowLeave) _confirmCancellation();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NearbyDriversMockMap(
                          scanning: _offers.isEmpty && !_selectionPending,
                        ),
                      ),
                      // Readable system icons without restoring a solid header.
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: MediaQuery.paddingOf(context).top + 75,
                        child: const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xEFFFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              DriverOffersMapControls(
                                onBack: _confirmCancellation,
                                onHelp: _showSafetyHelp,
                              ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Padding(
                                        // Reserve room for the unseen-offer
                                        // button so it never hides card actions.
                                        padding: EdgeInsets.only(
                                          bottom: _unseenOffers > 0 &&
                                                  !_followingLatest
                                              ? 64
                                              : 0,
                                        ),
                                        child: _buildOffersArea(),
                                      ),
                                    ),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: math.max(
                      0.0,
                      constraints.maxHeight -
                          MediaQuery.paddingOf(context).top -
                          160,
                    ),
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
      ),
    );
  }

  Widget _buildOffersArea() {
    if (_offers.isEmpty) return const SizedBox.shrink();

    return Listener(
      onPointerDown: (_) => _touchingList = true,
      onPointerUp: (_) => _finishTouch(),
      onPointerCancel: (_) => _finishTouch(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
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
