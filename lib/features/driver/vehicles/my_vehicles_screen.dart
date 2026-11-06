import 'package:flutter/material.dart';

import '../../auth/auth_session.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key, this.session});

  final AuthSession? session;

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  AuthSession get _session => widget.session ?? authSession;
  late final Object? _owner = _session.user?['id'];
  late Future<Map<String, dynamic>> _vehicles;

  @override
  void initState() {
    super.initState();
    _session.addListener(_accountChanged);
    _vehicles = _load();
  }

  Future<Map<String, dynamic>> _load() => _session.vehicles(accountId: _owner);

  void _accountChanged() {
    if (_session.user?['id'] == _owner) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.user?['id'] != _owner) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _session.removeListener(_accountChanged);
    super.dispose();
  }

  Future<void> _open([Map<String, dynamic>? vehicle]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicle: vehicle)),
    );
    if (mounted && saved == true) setState(() => _vehicles = _load());
  }

  String _status(Object? status) => switch (status) {
    'approved' => 'Approved',
    'rejected' => 'Rejected',
    _ => 'Submitted',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Vehicles'),
      actions: [
        if (_session.user?['id'] == _owner)
          IconButton(
            onPressed: _open,
            icon: const Icon(Icons.add),
            tooltip: 'Add Vehicle',
          ),
      ],
    ),
    body: _session.user?['id'] != _owner
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
                          '${vehicle['registration_number']} · ${_status(vehicle['status'])} · Version ${vehicle['version']}'
                          '${vehicle['rejection_reason'] is String && (vehicle['rejection_reason'] as String).isNotEmpty ? '\nReason: ${vehicle['rejection_reason']}' : ''}',
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
