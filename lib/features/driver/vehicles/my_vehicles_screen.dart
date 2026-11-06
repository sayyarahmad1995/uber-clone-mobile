import 'package:flutter/material.dart';

import '../../auth/auth_session.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  late final Object? _owner = authSession.user?['id'];
  late Future<Map<String, dynamic>> _vehicles;

  @override
  void initState() {
    super.initState();
    authSession.addListener(_accountChanged);
    _vehicles = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      authSession.vehicles(accountId: _owner);

  void _accountChanged() {
    if (authSession.user?['id'] == _owner) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && authSession.user?['id'] != _owner) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    authSession.removeListener(_accountChanged);
    super.dispose();
  }

  Future<void> _open([Map<String, dynamic>? vehicle]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicle: vehicle)),
    );
    if (mounted && saved == true) setState(() => _vehicles = _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Vehicles'),
      actions: [
        if (authSession.user?['id'] == _owner)
          IconButton(
            onPressed: _open,
            icon: const Icon(Icons.add),
            tooltip: 'Add Vehicle',
          ),
      ],
    ),
    body: authSession.user?['id'] != _owner
        ? const SizedBox.shrink()
        : FutureBuilder<Map<String, dynamic>>(
            future: _vehicles,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() => _vehicles = _load()),
                    child: Text('${authErrorMessage(snapshot.error!)} Retry'),
                  ),
                );
              }
              final vehicles = (snapshot.data?['vehicles'] as List)
                  .cast<Map<String, dynamic>>();
              if (vehicles.isEmpty) {
                return const Center(child: Text('No vehicle submissions yet.'));
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final vehicle in vehicles)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.directions_car_outlined),
                        title: Text('${vehicle['make']} ${vehicle['model']}'),
                        subtitle: Text(
                          '${vehicle['registration_number']} · Submitted · Version ${vehicle['version']}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _open(vehicle),
                      ),
                    ),
                ],
              );
            },
          ),
  );
}
