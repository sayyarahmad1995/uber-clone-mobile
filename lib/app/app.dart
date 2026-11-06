import 'package:flutter/material.dart';

import '../features/auth/auth_session.dart';
import '../features/rider/home/rider_shell.dart';
import '../features/welcome/welcome_screen.dart';
import 'higo_theme.dart';
import 'app_mode_controller.dart';
import '../features/driver/home/driver_shell.dart';

class HiGoApp extends StatefulWidget {
  const HiGoApp({super.key});

  @override
  State<HiGoApp> createState() => _HiGoAppState();
}

class _HiGoAppState extends State<HiGoApp> {
  late Future<void> _startup = authSession.restore();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HiGO',
    debugShowCheckedModeBanner: false,
    theme: HiGoTheme.light,
    home: FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    setState(() => _startup = authSession.restore()),
                child: const Text('Retry connecting to HiGO'),
              ),
            ),
          );
        }
        return ListenableBuilder(
          listenable: Listenable.merge([authSession, appMode]),
          builder: (_, _) => authSession.authenticated
              ? appMode.value == HiGoAppMode.driver && appMode.canUseDriverMode
                    ? const DriverShell(key: ValueKey('driver-shell'))
                    : const RiderShell(key: ValueKey('rider-shell'))
              : const WelcomeScreen(),
        );
      },
    ),
  );
}
