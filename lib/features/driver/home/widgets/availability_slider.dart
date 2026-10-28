import 'package:flutter/material.dart';

class AvailabilitySlider extends StatefulWidget {
  const AvailabilitySlider({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  State<AvailabilitySlider> createState() => _AvailabilitySliderState();
}

class _AvailabilitySliderState extends State<AvailabilitySlider> {
  static const double _height = 58;
  static const double _thumbSize = 50;
  static const double _padding = 4;

  double? _dragOffset;

  @override
  void didUpdateWidget(covariant AvailabilitySlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOnline != widget.isOnline) {
      _dragOffset = null;
    }
  }

  void _finishDrag(double maxTravel) {
    final position = _dragOffset ?? (widget.isOnline ? maxTravel : 0.0);

    final fraction = maxTravel == 0 ? 0.0 : position / maxTravel;

    bool? nextValue;

    if (!widget.isOnline && fraction >= 0.75) {
      nextValue = true;
    } else if (widget.isOnline && fraction <= 0.25) {
      nextValue = false;
    }

    setState(() {
      _dragOffset = null;
    });

    if (nextValue != null) {
      widget.onChanged(nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTravel = (constraints.maxWidth - _thumbSize - _padding * 2)
            .clamp(0.0, double.infinity);

        final position = (_dragOffset ?? (widget.isOnline ? maxTravel : 0.0))
            .clamp(0.0, maxTravel);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            setState(() {
              _dragOffset = widget.isOnline ? maxTravel : 0.0;
            });
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset = ((_dragOffset ?? position) + details.delta.dx)
                  .clamp(0.0, maxTravel);
            });
          },
          onHorizontalDragEnd: (_) => _finishDrag(maxTravel),
          onHorizontalDragCancel: () {
            setState(() => _dragOffset = null);
          },
          child: Semantics(
            label: widget.isOnline
                ? 'Slide left to go offline'
                : 'Slide right to go online',
            value: widget.isOnline ? 'Online' : 'Offline',
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: const Color(0xFFDCF7E9),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 58),
                    child: Text(
                      widget.isOnline
                          ? 'Slide left to go offline'
                          : 'Slide right to go online',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF087C43),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dragOffset == null
                        ? const Duration(milliseconds: 180)
                        : Duration.zero,
                    curve: Curves.easeOut,
                    left: _padding + position,
                    top: _padding,
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF079653),
                      ),
                      child: Icon(
                        widget.isOnline
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
