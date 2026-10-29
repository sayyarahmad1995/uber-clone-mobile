import 'package:flutter/material.dart';

import '../../app/higo_theme.dart';
import 'higo_map_controls.dart';

class HiGoHomeHeader extends StatelessWidget {
  const HiGoHomeHeader({
    super.key,
    required this.firstName,
    required this.onAccountTap,
    required this.onNotifications,
    required this.onRecenter,
    required this.onNorthUp,
    this.photo,
    this.showMapControls = true,
  });

  final String firstName;
  final ImageProvider? photo;
  final bool showMapControls;
  final VoidCallback onAccountTap;
  final VoidCallback onNotifications;
  final VoidCallback onRecenter;
  final VoidCallback onNorthUp;

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = firstName.trim().isEmpty
        ? 'Welcome'
        : firstName.trim().split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Material(
            color: Colors.white,
            elevation: 2,
            shadowColor: const Color(0x22000000),
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: onAccountTap,
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEFECFF),
                      backgroundImage: photo,
                      child: photo == null
                          ? Text(
                              name == 'Welcome' ? 'H' : name[0].toUpperCase(),
                              style: const TextStyle(
                                color: HiGoTheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: HiGoTheme.navy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right,
                                size: 17,
                                color: HiGoTheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 10),
        HiGoMapControls(
          onNotifications: onNotifications,
          onRecenter: onRecenter,
          onNorthUp: onNorthUp,
          showMapButtons: showMapControls,
        ),
      ],
    );
  }
}
