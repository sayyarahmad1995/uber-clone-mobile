class MockDriverOffer {
  const MockDriverOffer({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.rating,
    required this.arrivalMinutes,
    required this.farePkr,
  });

  final String id;
  final String name;
  final String vehicle;
  final double rating;
  final int arrivalMinutes;
  final int farePkr;
}

const mockDriverOffers = [
  MockDriverOffer(
    id: 'driver_1',
    name: 'Ahmed',
    vehicle: 'Suzuki Alto',
    rating: 4.9,
    arrivalMinutes: 4,
    farePkr: 650,
  ),
  MockDriverOffer(
    id: 'driver_2',
    name: 'Bilal',
    vehicle: 'Toyota Corolla',
    rating: 4.8,
    arrivalMinutes: 6,
    farePkr: 900,
  ),
  MockDriverOffer(
    id: 'driver_3',
    name: 'Usman',
    vehicle: 'Suzuki Cultus',
    rating: 4.7,
    arrivalMinutes: 3,
    farePkr: 750,
  ),
];
