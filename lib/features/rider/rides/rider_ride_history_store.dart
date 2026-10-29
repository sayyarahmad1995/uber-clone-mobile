import 'package:flutter/foundation.dart';

class CompletedRiderRide {
  const CompletedRiderRide({
    required this.pickup,
    required this.destination,
    required this.category,
    required this.driverName,
    required this.vehicle,
    required this.farePkr,
    required this.completedAt,
  });

  final String pickup;
  final String destination;
  final String category;
  final String driverName;
  final String vehicle;
  final int farePkr;
  final DateTime completedAt;
}

class RiderRideHistoryStore extends ChangeNotifier {
  final Map<Object, CompletedRiderRide> _completedRides = {};

  List<CompletedRiderRide> get completedRides =>
      List.unmodifiable(_completedRides.values.toList().reversed);

  bool recordCompletedRide({
    required Object tripKey,
    required CompletedRiderRide ride,
  }) {
    if (_completedRides.containsKey(tripKey)) {
      return false;
    }

    _completedRides[tripKey] = ride;
    notifyListeners();
    return true;
  }

  void clear() {
    if (_completedRides.isEmpty) return;

    _completedRides.clear();
    notifyListeners();
  }
}

final riderRideHistoryStore = RiderRideHistoryStore();
