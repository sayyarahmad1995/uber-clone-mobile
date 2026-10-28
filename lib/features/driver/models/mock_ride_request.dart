import 'package:flutter/foundation.dart';
import 'mock_driver_vehicle.dart';

class MockRideRequest {
  const MockRideRequest({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.category,
    required this.estimatedFarePkr,
    required this.riderName,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final String id;
  final String pickup;
  final String destination;
  final String category;
  final int estimatedFarePkr;
  final String riderName;
  final double distanceKm;
  final int durationMinutes;
}

class MockDriverBid {
  const MockDriverBid({
    required this.requestId,
    required this.farePkr,
    this.selectedByRider = false,
  });

  final String requestId;
  final int farePkr;
  final bool selectedByRider;

  MockDriverBid copyWith({int? farePkr, bool? selectedByRider}) {
    return MockDriverBid(
      requestId: requestId,
      farePkr: farePkr ?? this.farePkr,
      selectedByRider: selectedByRider ?? this.selectedByRider,
    );
  }
}

const mockIncomingRequests = <MockRideRequest>[
  MockRideRequest(
    id: 'request_001',
    pickup: 'F-8, Islamabad',
    destination: 'Centaurus Mall, F-8',
    category: 'Mini Car',
    estimatedFarePkr: 480,
    riderName: 'Ali',
    distanceKm: 4.8,
    durationMinutes: 12,
  ),
  MockRideRequest(
    id: 'request_002',
    pickup: 'G-11, Islamabad',
    destination: 'Blue Area, Islamabad',
    category: 'Comfort',
    estimatedFarePkr: 650,
    riderName: 'Sara',
    distanceKm: 6.2,
    durationMinutes: 15,
  ),
  MockRideRequest(
    id: 'request_003',
    pickup: 'I-8, Islamabad',
    destination: 'Islamabad Airport',
    category: 'A/C Car',
    estimatedFarePkr: 1350,
    riderName: 'Hamza',
    distanceKm: 18.4,
    durationMinutes: 22,
  ),
];

enum DemoAssignmentStage {
  selected,
  confirmed,
  arrived,
  inProgress,
  awaitingCash,
}

extension DemoAssignmentStageLabel on DemoAssignmentStage {
  String get label => switch (this) {
    DemoAssignmentStage.selected => 'Confirm assignment',
    DemoAssignmentStage.confirmed => 'Navigate to pickup',
    DemoAssignmentStage.arrived => 'Verify rider',
    DemoAssignmentStage.inProgress => 'Trip in progress',
    DemoAssignmentStage.awaitingCash => 'Collect cash',
  };
}

/// Temporary in-memory UI state.
/// No persistence, network calls, or business rules.
class DriverDemoStore extends ChangeNotifier {
  DriverDemoStore._();

  static final DriverDemoStore instance = DriverDemoStore._();
  final Map<String, DemoAssignmentStage> _assignmentStages = {};

  bool _isOnline = false;
  final Map<String, MockDriverBid> _bids = {};
  final Map<String, MockCompletedDriverTrip> _completedTrips = {};
  final Set<String> _tripsInProgress = {};

  bool get isOnline => _isOnline;

  List<MockRideRequest> get availableRequests => _isOnline
      ? mockIncomingRequests.where((request) {
          return !_bids.containsKey(request.id) &&
              !_tripsInProgress.contains(request.id) &&
              !_completedTrips.containsKey(request.id);
        }).toList()
      : [];

  List<MockDriverBid> get activeBids => List.unmodifiable(_bids.values);

  MockDriverBid? bidFor(String requestId) => _bids[requestId];

  MockRideRequest requestFor(String requestId) =>
      mockIncomingRequests.firstWhere((request) => request.id == requestId);

  void setOnline(bool value) {
    // Going online requires an approved,
    // explicitly selected vehicle.
    if (value && !canGoOnline) {
      return;
    }

    // Avoid unnecessary UI rebuilds.
    if (_isOnline == value) {
      return;
    }

    _isOnline = value;
    notifyListeners();
  }

  void submitBid(String requestId, int farePkr) {
    _bids[requestId] = MockDriverBid(requestId: requestId, farePkr: farePkr);
    notifyListeners();
  }

  void withdrawBid(String requestId) {
    _bids.remove(requestId);
    notifyListeners();
  }

  void simulateRiderSelection(String requestId) {
    selectDemoBid(requestId);
  }

  void resetDemo() {
    _bids.clear();
    _completedTrips.clear();
    _tripsInProgress.clear();
    _assignmentStages.clear();

    _isOnline = false;
    _selectedVehicleId = null;
    _vehicles
      ..clear()
      ..addAll(mockDriverVehicles);
    _nextDemoVehicleNumber = 1;

    notifyListeners();
  }

  // Add these getters.
  List<MockCompletedDriverTrip> get completedTrips {
    final items = _completedTrips.values.toList();

    items.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return List.unmodifiable(items);
  }

  int get totalDemoEarningsPkr =>
      _completedTrips.values.fold(0, (total, trip) => total + trip.farePkr);

  bool isTripInProgress(String requestId) =>
      _tripsInProgress.contains(requestId);

  bool isTripCompleted(String requestId) =>
      _completedTrips.containsKey(requestId);

  // Call after successful mock rider verification.
  void startDemoTrip(String requestId) {
    if (_assignmentStages[requestId] != DemoAssignmentStage.arrived) {
      return;
    }

    _tripsInProgress.add(requestId);
    _assignmentStages[requestId] = DemoAssignmentStage.inProgress;
    notifyListeners();
  }

  // Call after mock cash receipt confirmation.
  void completeDemoTrip(MockRideRequest request, int farePkr) {
    if (_completedTrips.containsKey(request.id)) return;

    _tripsInProgress.remove(request.id);
    _bids.remove(request.id);
    _assignmentStages.remove(request.id);

    _completedTrips[request.id] = MockCompletedDriverTrip(
      request: request,
      farePkr: farePkr,
      completedAt: DateTime.now(),
    );

    notifyListeners();
  }

  // Save optional demo rider feedback.
  void rateDemoRider({
    required String requestId,
    required int rating,
    String? feedback,
  }) {
    final trip = _completedTrips[requestId];

    if (trip == null || rating < 1 || rating > 5) {
      return;
    }

    _completedTrips[requestId] = trip.copyWith(
      riderRating: rating,
      feedback: feedback,
    );

    notifyListeners();
  }

  String? get activeAssignmentId {
    for (final entry in _assignmentStages.entries) {
      if (!_completedTrips.containsKey(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  MockRideRequest? get activeAssignment {
    final id = activeAssignmentId;
    return id == null ? null : requestFor(id);
  }

  MockDriverBid? get activeAssignmentBid {
    final id = activeAssignmentId;
    return id == null ? null : bidFor(id);
  }

  DemoAssignmentStage? assignmentStage(String requestId) =>
      _assignmentStages[requestId];

  bool get hasActiveAssignment => activeAssignmentId != null;

  bool canSelectBid(String requestId) =>
      _bids.containsKey(requestId) &&
      !_completedTrips.containsKey(requestId) &&
      (activeAssignmentId == null || activeAssignmentId == requestId);

  bool selectDemoBid(String requestId) {
    if (!canSelectBid(requestId)) return false;

    final bid = _bids[requestId]!;

    _bids[requestId] = bid.copyWith(selectedByRider: true);

    _assignmentStages.putIfAbsent(
      requestId,
      () => DemoAssignmentStage.selected,
    );

    notifyListeners();
    return true;
  }

  void confirmDemoAssignment(String requestId) {
    if (_assignmentStages[requestId] != DemoAssignmentStage.selected) {
      return;
    }

    _assignmentStages[requestId] = DemoAssignmentStage.confirmed;
    notifyListeners();
  }

  void arriveAtDemoPickup(String requestId) {
    if (_assignmentStages[requestId] != DemoAssignmentStage.confirmed) {
      return;
    }

    _assignmentStages[requestId] = DemoAssignmentStage.arrived;
    notifyListeners();
  }

  void advanceToCashCollection(String requestId) {
    if (_assignmentStages[requestId] != DemoAssignmentStage.inProgress) {
      return;
    }

    _assignmentStages[requestId] = DemoAssignmentStage.awaitingCash;
    notifyListeners();
  }

  String? _selectedVehicleId;

  final List<MockDriverVehicle> _vehicles = [...mockDriverVehicles];

  int _nextDemoVehicleNumber = 1;

  List<MockDriverVehicle> get vehicles => List.unmodifiable(_vehicles);

  MockDriverVehicle registerDemoVehicle({
    required String make,
    required String model,
    required String registrationNumber,
    required String category,
    required String serviceId,
    String? categoryId,
  }) {
    final registration = registrationNumber.trim().toUpperCase();

    if (make.trim().isEmpty ||
        model.trim().isEmpty ||
        category.trim().isEmpty ||
        registration.isEmpty) {
      throw ArgumentError('Complete all vehicle details.');
    }

    if (_vehicles.any(
      (vehicle) => vehicle.registrationNumber.toUpperCase() == registration,
    )) {
      throw StateError('This registration number already exists.');
    }

    final vehicle = MockDriverVehicle(
      id: 'demo_vehicle_${_nextDemoVehicleNumber++}',
      make: make.trim(),
      model: model.trim(),
      registrationNumber: registration,
      category: category.trim(),
      approvalStatus: MockVehicleApprovalStatus.pending,
      serviceId: serviceId,
      categoryId: categoryId,
    );

    _vehicles.add(vehicle);
    notifyListeners();

    return vehicle;
  }

  List<MockDriverVehicle> get approvedVehicles =>
      vehicles.where((vehicle) => vehicle.isApproved).toList();

  String? get selectedVehicleId => _selectedVehicleId;

  MockDriverVehicle? get selectedVehicle {
    for (final vehicle in approvedVehicles) {
      if (vehicle.id == _selectedVehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  bool get canGoOnline => selectedVehicle != null;

  bool selectVehicle(String vehicleId) {
    // Do not switch vehicles while online or during
    // an active assignment in this mock implementation.
    if (isOnline || hasActiveAssignment) {
      return false;
    }

    MockDriverVehicle? match;

    for (final vehicle in approvedVehicles) {
      if (vehicle.id == vehicleId) {
        match = vehicle;
        break;
      }
    }

    if (match == null) return false;

    if (_selectedVehicleId == vehicleId) return true;

    _selectedVehicleId = vehicleId;
    notifyListeners();
    return true;
  }
}

class MockCompletedDriverTrip {
  const MockCompletedDriverTrip({
    required this.request,
    required this.farePkr,
    required this.completedAt,
    this.riderRating,
    this.feedback,
  });

  final MockRideRequest request;
  final int farePkr;
  final DateTime completedAt;
  final int? riderRating;
  final String? feedback;

  MockCompletedDriverTrip copyWith({int? riderRating, String? feedback}) {
    return MockCompletedDriverTrip(
      request: request,
      farePkr: farePkr,
      completedAt: completedAt,
      riderRating: riderRating ?? this.riderRating,
      feedback: feedback ?? this.feedback,
    );
  }
}
