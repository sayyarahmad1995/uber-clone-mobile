class VehicleServiceCategory {
  const VehicleServiceCategory({required this.id, required this.name});

  final String id;
  final String name;
}

class VehicleService {
  const VehicleService({
    required this.id,
    required this.name,
    required this.description,
    this.categories = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<VehicleServiceCategory> categories;

  bool get hasCategories => categories.isNotEmpty;
}

abstract class VehicleServiceCatalog {
  Future<List<VehicleService>> loadServices();
}

class MockVehicleServiceCatalog implements VehicleServiceCatalog {
  const MockVehicleServiceCatalog();

  @override
  Future<List<VehicleService>> loadServices() async {
    return const [
      VehicleService(
        id: 'city_ride',
        name: 'City Ride',
        description: 'Trips within a city',
        categories: [
          VehicleServiceCategory(id: 'moto', name: 'Moto'),
          VehicleServiceCategory(id: 'mini_car', name: 'Mini Car'),
          VehicleServiceCategory(id: 'comfort', name: 'Comfort'),
          VehicleServiceCategory(id: 'ac_car', name: 'A/C Car'),
          VehicleServiceCategory(id: 'premium', name: 'Premium'),
        ],
      ),
      VehicleService(
        id: 'city_to_city',
        name: 'City-to-City',
        description: 'Travel between cities',
      ),
      VehicleService(
        id: 'courier',
        name: 'Courier',
        description: 'Parcel transportation',
      ),
      VehicleService(
        id: 'delivery',
        name: 'Delivery',
        description: 'Local delivery services',
      ),
      VehicleService(
        id: 'freight',
        name: 'Freight',
        description: 'Cargo and goods transport',
        categories: [
          VehicleServiceCategory(id: 'light', name: 'Light Freight'),
          VehicleServiceCategory(id: 'heavy', name: 'Heavy Freight'),
        ],
      ),
    ];
  }
}
