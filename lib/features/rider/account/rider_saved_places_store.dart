import 'package:flutter/foundation.dart';

enum SavedPlaceType { home, work, custom }

@immutable
class MockPlaceCandidate {
  const MockPlaceCandidate({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

// Illustrative mock coordinates, not verified geocoding.
const mockPlaceCandidates = <MockPlaceCandidate>[
  MockPlaceCandidate(
    id: 'f8-markaz',
    name: 'F-8 Markaz',
    address: 'Street 12, F-8 Markaz, Islamabad',
    latitude: 33.7112,
    longitude: 73.0382,
  ),
  MockPlaceCandidate(
    id: 'centaurus',
    name: 'Centaurus Mall',
    address: 'Jinnah Avenue, F-8, Islamabad',
    latitude: 33.7076,
    longitude: 73.0500,
  ),
  MockPlaceCandidate(
    id: 'blue-area',
    name: 'Blue Area',
    address: 'Blue Area, Islamabad',
    latitude: 33.7161,
    longitude: 73.0657,
  ),
  MockPlaceCandidate(
    id: 'nust',
    name: 'NUST H-12',
    address: 'H-12, Islamabad',
    latitude: 33.6434,
    longitude: 72.9900,
  ),
  MockPlaceCandidate(
    id: 'faisal-mosque',
    name: 'Faisal Mosque',
    address: 'E-8, Islamabad',
    latitude: 33.7295,
    longitude: 73.0372,
  ),
  MockPlaceCandidate(
    id: 'bahria-town',
    name: 'Bahria Town',
    address: 'Bahria Town, Rawalpindi',
    latitude: 33.5246,
    longitude: 73.1037,
  ),
];

@immutable
class RiderSavedPlace {
  const RiderSavedPlace({
    required this.id,
    required this.type,
    required this.label,
    required this.location,
  });

  final String id;
  final SavedPlaceType type;
  final String label;
  final MockPlaceCandidate location;

  String get address => location.address;
  double get latitude => location.latitude;
  double get longitude => location.longitude;
}

class RiderSavedPlacesStore extends ChangeNotifier {
  final List<RiderSavedPlace> _places = [];
  int _nextId = 1;

  List<RiderSavedPlace> get places => List.unmodifiable(_places);

  RiderSavedPlace? placeForType(SavedPlaceType type) {
    for (final place in _places) {
      if (place.type == type) return place;
    }
    return null;
  }

  List<MockPlaceCandidate> search(String query) {
    final text = query.trim().toLowerCase();

    if (text.isEmpty) {
      return List.unmodifiable(mockPlaceCandidates);
    }

    return List.unmodifiable(
      mockPlaceCandidates.where((candidate) {
        return candidate.name.toLowerCase().contains(text) ||
            candidate.address.toLowerCase().contains(text);
      }),
    );
  }

  void save({
    String? id,
    required SavedPlaceType type,
    required String label,
    required MockPlaceCandidate location,
  }) {
    if (!mockPlaceCandidates.any((candidate) => candidate.id == location.id)) {
      // Existing saved places also carry catalog locations.
      // Arbitrary free-text addresses are not supported yet.
      throw ArgumentError('Select a suggested location.');
    }

    final existingIndex = id == null
        ? -1
        : _places.indexWhere((p) => p.id == id);

    if (id != null && existingIndex == -1) {
      throw StateError('Saved place no longer exists.');
    }

    final cleanedLabel = label.trim();

    if (type == SavedPlaceType.custom && cleanedLabel.isEmpty) {
      throw ArgumentError('Place label is required.');
    }

    final resolvedLabel = switch (type) {
      SavedPlaceType.home => 'Home',
      SavedPlaceType.work => 'Work',
      SavedPlaceType.custom => cleanedLabel,
    };

    // Home and Work are unique shortcuts.
    // Reassigning one replaces the previous shortcut.
    final resolvedId =
        id ??
        (type == SavedPlaceType.custom ? null : placeForType(type)?.id) ??
        'mock-place-${_nextId++}';

    _places.removeWhere(
      (p) =>
          p.id == resolvedId ||
          (type != SavedPlaceType.custom && p.type == type),
    );

    final updated = RiderSavedPlace(
      id: resolvedId,
      type: type,
      label: resolvedLabel,
      location: location,
    );

    _places.add(updated);
    notifyListeners();
  }

  void delete(String id) {
    final oldLength = _places.length;
    _places.removeWhere((p) => p.id == id);

    if (_places.length != oldLength) {
      notifyListeners();
    }
  }
}

final riderSavedPlacesStore = RiderSavedPlacesStore();
