import 'package:flutter/material.dart';

class RideCategory {
  const RideCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.estimatedFarePkr,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int? estimatedFarePkr;
}

// Temporary UI data. The Go API will eventually
// supply categories and estimated fares.
const mockRideCategories = <RideCategory>[
  RideCategory(
    id: 'moto',
    name: 'Moto',
    description: 'Motorcycle ride',
    icon: Icons.two_wheeler,
    estimatedFarePkr: 280,
  ),
  RideCategory(
    id: 'mini',
    name: 'Mini Car',
    description: 'Economy car',
    icon: Icons.directions_car,
    estimatedFarePkr: 520,
  ),
  RideCategory(
    id: 'comfort',
    name: 'Comfort',
    description: 'Comfortable ride',
    icon: Icons.airline_seat_recline_extra,
    estimatedFarePkr: 720,
  ),
  RideCategory(
    id: 'ac_car',
    name: 'A/C Car',
    description: 'Air-conditioned ride',
    icon: Icons.ac_unit,
    estimatedFarePkr: 850,
  ),
  RideCategory(
    id: 'premium',
    name: 'Premium',
    description: 'Premium vehicle',
    icon: Icons.local_taxi,
    estimatedFarePkr: 1250,
  ),
];
