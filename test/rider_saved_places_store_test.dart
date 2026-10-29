import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/features/rider/account/rider_saved_places_store.dart';

void main() {
  late RiderSavedPlacesStore store;

  setUp(() {
    store = RiderSavedPlacesStore();
  });

  tearDown(() {
    store.dispose();
  });

  test('starts without saved places', () {
    expect(store.places, isEmpty);
  });

  test('searches mock locations case-insensitively', () {
    final results = store.search('CENTaurus');

    expect(results.length, 1);
    expect(results.first.id, 'centaurus');
  });

  test('searches by address', () {
    final results = store.search('Islamabad');

    expect(results, isNotEmpty);
    expect(
      results.every((place) => place.address.contains('Islamabad')),
      isTrue,
    );
  });

  test('adds a Home shortcut', () {
    store.save(
      type: SavedPlaceType.home,
      label: '',
      location: mockPlaceCandidates.first,
    );

    final home = store.placeForType(SavedPlaceType.home);

    expect(home, isNotNull);
    expect(home!.label, 'Home');
    expect(home.address, mockPlaceCandidates.first.address);
  });

  test('replaces Home instead of duplicating it', () {
    store.save(
      type: SavedPlaceType.home,
      label: '',
      location: mockPlaceCandidates[0],
    );

    final originalId = store.placeForType(SavedPlaceType.home)!.id;

    store.save(
      type: SavedPlaceType.home,
      label: '',
      location: mockPlaceCandidates[1],
    );

    expect(store.places.length, 1);
    expect(store.placeForType(SavedPlaceType.home)!.id, originalId);
    expect(
      store.placeForType(SavedPlaceType.home)!.address,
      mockPlaceCandidates[1].address,
    );
  });

  test('keeps Home and Work separate', () {
    store.save(
      type: SavedPlaceType.home,
      label: '',
      location: mockPlaceCandidates[0],
    );

    store.save(
      type: SavedPlaceType.work,
      label: '',
      location: mockPlaceCandidates[1],
    );

    expect(store.places.length, 2);
    expect(store.placeForType(SavedPlaceType.home), isNotNull);
    expect(store.placeForType(SavedPlaceType.work), isNotNull);
  });

  test('adds and edits a custom place', () {
    store.save(
      type: SavedPlaceType.custom,
      label: 'Gym',
      location: mockPlaceCandidates[0],
    );

    final originalId = store.places.first.id;

    store.save(
      id: originalId,
      type: SavedPlaceType.custom,
      label: 'Fitness Center',
      location: mockPlaceCandidates[1],
    );

    expect(store.places.length, 1);
    expect(store.places.first.id, originalId);
    expect(store.places.first.label, 'Fitness Center');
    expect(store.places.first.address, mockPlaceCandidates[1].address);
  });

  test('rejects empty custom labels', () {
    expect(
      () => store.save(
        type: SavedPlaceType.custom,
        label: '   ',
        location: mockPlaceCandidates.first,
      ),
      throwsArgumentError,
    );
  });

  test('rejects locations outside the mock catalog', () {
    const unknown = MockPlaceCandidate(
      id: 'unknown',
      name: 'Unknown',
      address: 'Unknown address',
      latitude: 0,
      longitude: 0,
    );

    expect(
      () => store.save(type: SavedPlaceType.home, label: '', location: unknown),
      throwsArgumentError,
    );
  });

  test('rejects editing an unknown saved-place ID', () {
    expect(
      () => store.save(
        id: 'missing-id',
        type: SavedPlaceType.custom,
        label: 'Gym',
        location: mockPlaceCandidates.first,
      ),
      throwsStateError,
    );
  });

  test('deletes a saved place', () {
    store.save(
      type: SavedPlaceType.custom,
      label: 'Gym',
      location: mockPlaceCandidates.first,
    );

    final id = store.places.first.id;
    store.delete(id);

    expect(store.places, isEmpty);
  });

  test('notifies listeners on save and delete', () {
    var notifications = 0;

    void listener() {
      notifications++;
    }

    store.addListener(listener);

    store.save(
      type: SavedPlaceType.home,
      label: '',
      location: mockPlaceCandidates.first,
    );

    store.delete(store.places.first.id);

    expect(notifications, 2);

    store.removeListener(listener);
  });
}
