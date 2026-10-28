enum MockVehicleApprovalStatus { approved, pending, rejected }

class MockDriverVehicle {
  const MockDriverVehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.registrationNumber,
    required this.category,
    required this.approvalStatus,
    this.serviceId,
    this.categoryId,
  });

  final String id;
  final String make;
  final String model;
  final String registrationNumber;
  final String category;
  final MockVehicleApprovalStatus approvalStatus;
  final String? serviceId;
  final String? categoryId;

  String get name => '$make $model';
  bool get isApproved => approvalStatus == MockVehicleApprovalStatus.approved;
}

const mockDriverVehicles = <MockDriverVehicle>[
  MockDriverVehicle(
    id: 'vehicle_1',
    make: 'Toyota',
    model: 'Aqua',
    registrationNumber: 'ABC-123',
    category: 'Mini Car',
    approvalStatus: MockVehicleApprovalStatus.approved,
    serviceId: 'city_ride',
    categoryId: 'mini_car',
  ),
  MockDriverVehicle(
    id: 'vehicle_2',
    make: 'Suzuki',
    model: 'Alto',
    registrationNumber: 'DEF-789',
    category: 'Mini Car',
    approvalStatus: MockVehicleApprovalStatus.approved,
    serviceId: 'city_ride',
    categoryId: 'mini_car',
  ),
  MockDriverVehicle(
    id: 'vehicle_3',
    make: 'Honda',
    model: 'Civic',
    registrationNumber: 'GHI-456',
    category: 'Comfort',
    approvalStatus: MockVehicleApprovalStatus.approved,
    serviceId: 'city_ride',
    categoryId: 'comfort',
  ),
  MockDriverVehicle(
    id: 'vehicle_4',
    make: 'Honda',
    model: 'City',
    registrationNumber: 'JKL-321',
    category: 'Comfort',
    approvalStatus: MockVehicleApprovalStatus.pending,
    serviceId: 'city_ride',
    categoryId: 'comfort',
  ),
  MockDriverVehicle(
    id: 'vehicle_5',
    make: 'Suzuki',
    model: 'Cultus',
    registrationNumber: 'MNO-654',
    category: 'Mini Car',
    approvalStatus: MockVehicleApprovalStatus.rejected,
    serviceId: 'city_ride',
    categoryId: 'mini_car',
  ),
];
