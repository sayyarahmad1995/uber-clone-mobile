class MockDriverOffer {
  const MockDriverOffer({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.rating,
    required this.arrivalMinutes,
    required this.farePkr,
    this.reviewCount = 0,
    this.vehicleColor = '',
    this.photoAsset,
  });

  final String id;
  final String name;
  final String vehicle;
  final String vehicleColor;
  final double rating;
  final int reviewCount;
  final int arrivalMinutes;
  final int farePkr;
  final String? photoAsset;

  MockDriverOffer withFare(int fare) => MockDriverOffer(
    id: id,
    name: name,
    vehicle: vehicle,
    vehicleColor: vehicleColor,
    rating: rating,
    reviewCount: reviewCount,
    arrivalMinutes: arrivalMinutes,
    farePkr: fare,
    photoAsset: photoAsset,
  );
}

String formatOfferFare(int amount) {
  final digits = amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return 'PKR $digits';
}

String compareDriverFare(int driverFare, int currentRiderFare) {
  final difference = driverFare - currentRiderFare;
  if (difference == 0) return 'Matches your offer';
  if (difference > 0) return '+ ${formatOfferFare(difference)}';
  return '${formatOfferFare(-difference)} below your offer';
}

// These demonstration offers are listed in chronological arrival order.
// The 450-PKR baseline is adjusted to the selected category's mock fare.
const mockDriverOffers = <MockDriverOffer>[
  MockDriverOffer(
    id: 'driver_1',
    name: 'Ahmed Khan',
    vehicle: 'Suzuki Alto',
    vehicleColor: 'White',
    rating: 4.9,
    reviewCount: 328,
    arrivalMinutes: 4,
    farePkr: 450,
  ),
  MockDriverOffer(
    id: 'driver_2',
    name: 'Bilal Ahmed',
    vehicle: 'Daihatsu Mira',
    vehicleColor: 'Silver',
    rating: 4.8,
    reviewCount: 214,
    arrivalMinutes: 2,
    farePkr: 480,
  ),
  MockDriverOffer(
    id: 'driver_3',
    name: 'Usman Ali',
    vehicle: 'Suzuki Wagon R',
    vehicleColor: 'Grey',
    rating: 4.9,
    reviewCount: 176,
    arrivalMinutes: 6,
    farePkr: 500,
  ),
  MockDriverOffer(
    id: 'driver_4',
    name: 'Hamza Tariq',
    vehicle: 'Suzuki Cultus',
    vehicleColor: 'Silver',
    rating: 4.7,
    reviewCount: 93,
    arrivalMinutes: 5,
    farePkr: 470,
  ),
  MockDriverOffer(
    id: 'driver_5',
    name: 'Saad Malik',
    vehicle: 'Toyota Vitz',
    vehicleColor: 'White',
    rating: 4.8,
    reviewCount: 157,
    arrivalMinutes: 3,
    farePkr: 490,
  ),
];

List<MockDriverOffer> mockOffersForFare(int proposedFarePkr) =>
    mockDriverOffers
        .map((offer) => offer.withFare(proposedFarePkr + offer.farePkr - 450))
        .toList(growable: false);
