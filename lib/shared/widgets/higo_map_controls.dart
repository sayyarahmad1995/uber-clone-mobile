import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';

class HiGoMapControls extends StatefulWidget {
  const HiGoMapControls({
    super.key,
    required this.onNotifications,
    required this.onRecenter,
    required this.onNorthUp,
  });

  final VoidCallback onNotifications;
  final VoidCallback onRecenter;
  final VoidCallback onNorthUp;

  @override
  State<HiGoMapControls> createState() => _HiGoMapControlsState();
}

class _HiGoMapControlsState extends State<HiGoMapControls> {
  bool _expanded = false;

  void _runAction(VoidCallback action) {
    action();

    if (mounted) {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapControlButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onPressed: widget.onNotifications,
        ),
        const SizedBox(height: 9),
        _MapControlButton(
          icon: _expanded ? Icons.close_rounded : Icons.menu_rounded,
          tooltip: _expanded ? 'Close map controls' : 'Open map controls',
          selected: _expanded,
          onPressed: () {
            setState(() => _expanded = !_expanded);
          },
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      const SizedBox(height: 9),
                      _MapControlButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Recenter map',
                        onPressed: () => _runAction(widget.onRecenter),
                      ),
                      const SizedBox(height: 9),
                      _MapControlButton(
                        icon: Icons.explore_outlined,
                        tooltip: 'North-up',
                        onPressed: () => _runAction(widget.onNorthUp),
                      ),
                    ],
                  )
                : const SizedBox(width: 46, height: 0),
          ),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? HiGoTheme.primary : Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 46,
        height: 46,
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(
            icon,
            size: 23,
            color: selected ? Colors.white : HiGoTheme.navy,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
