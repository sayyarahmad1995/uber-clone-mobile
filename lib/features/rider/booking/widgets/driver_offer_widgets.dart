import 'package:flutter/material.dart';

import '../../../../app/higo_theme.dart';
import '../mock_driver_offer.dart';
class DriverOffersHeader extends StatelessWidget {
  const DriverOffersHeader({
    required this.count,
    required this.onBack,
    required this.onHelp,
  });

  final int count;
  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF7FFFFFF),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: HiGoTheme.navy),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const Expanded(
                child: Text(
                  'Driver offers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HiGoTheme.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Safety and help',
                onPressed: onHelp,
                icon: const Icon(
                  Icons.shield_outlined,
                  color: HiGoTheme.primary,
                ),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xFF00A870)),
              Text(
                '$count ${count == 1 ? 'offer' : 'offers'} · Request is live',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: HiGoTheme.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DriverOfferCard extends StatelessWidget {
  const DriverOfferCard({
    super.key,
    required this.offer,
    required this.proposedFarePkr,
    required this.pending,
    required this.enabled,
    required this.onDetails,
    required this.onDecline,
    required this.onChoose,
  });

  final MockDriverOffer offer;
  final int proposedFarePkr;
  final bool pending;
  final bool enabled;
  final VoidCallback onDetails;
  final VoidCallback onDecline;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final matches = offer.farePkr == proposedFarePkr;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HiGoTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x190F1B4B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DriverAvatar(offer: offer),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HiGoTheme.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Color(0xFFF1A900),
                        ),
                        Flexible(
                          child: Text(
                            ' ${offer.rating.toStringAsFixed(1)} '
                            '(${offer.reviewCount})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HiGoTheme.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${offer.vehicle} · ${offer.vehicleColor}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HiGoTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.navigation_rounded,
                          color: HiGoTheme.secondaryText,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${offer.arrivalMinutes} min away',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HiGoTheme.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatOfferFare(offer.farePkr),
                        style: const TextStyle(
                          color: HiGoTheme.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      compareDriverFare(offer.farePkr, proposedFarePkr),
                      textAlign: TextAlign.end,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: matches
                            ? const Color(0xFF079C5C)
                            : HiGoTheme.secondaryText,
                        fontSize: 11,
                        fontWeight: matches
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Divider(height: 1, color: HiGoTheme.border),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 315 || largeText;
              final details = TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  foregroundColor: HiGoTheme.primary,
                ),
                child: const Text('View details'),
              );
              final decline = TextButton(
                onPressed: enabled ? onDecline : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: const Color(0xFFB4232B),
                  backgroundColor: const Color(0xFFFFE3E6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Decline'),
              );
              final choose = FilledButton(
                onPressed: enabled ? onChoose : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: HiGoTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: pending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Choose'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: details),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: decline),
                        const SizedBox(width: 10),
                        Expanded(child: choose),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 13, child: details),
                  const SizedBox(width: 8),
                  Expanded(flex: 11, child: decline),
                  const SizedBox(width: 10),
                  Expanded(flex: 12, child: choose),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.offer});
  final MockDriverOffer offer;

  @override
  Widget build(BuildContext context) {
    final initials = offer.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFEDEEFF),
      foregroundImage:
          offer.photoAsset == null ? null : AssetImage(offer.photoAsset!),
      child: Text(
        initials,
        style: const TextStyle(
          color: HiGoTheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class DriverOfferBottomSheet extends StatelessWidget {
  const DriverOfferBottomSheet({
    required this.pickup,
    required this.destination,
    required this.proposedFarePkr,
    required this.onIncreaseFare,
    required this.onCancel,
  });

  final String pickup;
  final String destination;
  final int proposedFarePkr;
  final VoidCallback onIncreaseFare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: HiGoTheme.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '$pickup  →  $destination',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HiGoTheme.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 345 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18;
                  final fare = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your offer',
                        style: TextStyle(color: HiGoTheme.secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatOfferFare(proposedFarePkr),
                        style: const TextStyle(
                          color: HiGoTheme.navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  );
                  final button = FilledButton(
                    onPressed: onIncreaseFare,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: HiGoTheme.primary,
                    ),
                    child: const Text('Increase fare'),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        fare,
                        const SizedBox(height: 8),
                        button,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: fare),
                      const SizedBox(width: 10),
                      button,
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Earlier offers remain available.',
                style: TextStyle(
                  color: HiGoTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 26, color: HiGoTheme.border),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: HiGoTheme.primary,
                ),
                child: const Text('Cancel request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
