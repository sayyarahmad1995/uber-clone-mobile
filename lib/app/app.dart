import 'package:flutter/material.dart';
import 'higo_theme.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/driver/home/driver_shell.dart';
import '../features/rider/home/rider_shell.dart';

const bool skipAuthenticationForDevelopment = true;

enum DevStartupMode { welcome, rider, driver }

const devStartupMode = DevStartupMode.driver; // Change this to test different startup modes

class HiGoApp extends StatelessWidget {
  const HiGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HiGO',
      debugShowCheckedModeBanner: false,
      theme: HiGoTheme.light,
      home: switch (devStartupMode) {
        DevStartupMode.welcome => const WelcomeScreen(),
        DevStartupMode.rider => const RiderShell(),
        DevStartupMode.driver => const DriverShell(),
      },
    );
  }
}
