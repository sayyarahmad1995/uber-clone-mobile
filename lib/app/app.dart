import 'package:flutter/material.dart';

import 'app_mode_controller.dart';
import 'higo_theme.dart';
import '../features/driver/home/driver_shell.dart';
import '../features/rider/home/rider_shell.dart';

const bool skipAuthenticationForDevelopment = true;

class HiGoApp extends StatelessWidget {
  const HiGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiGO',
      debugShowCheckedModeBanner: false,
      theme: HiGoTheme.light,
      home: ValueListenableBuilder<HiGoAppMode>(
        valueListenable: hiGoAppMode,
        builder: (context, mode, _) {
          return switch (mode) {
            HiGoAppMode.rider => const RiderShell(key: ValueKey('rider-shell')),
            HiGoAppMode.driver => const DriverShell(
              key: ValueKey('driver-shell'),
            ),
          };
        },
      ),
    );
  }
}
