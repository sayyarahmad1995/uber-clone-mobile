import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/features/rider/rides/rider_ride_history_store.dart';

void main() {
  late RiderRideHistoryStore store;

  CompletedRiderRide sampleRide(String destination) {
    return CompletedRiderRide(
      pickup: 'Centaurus Mall, Islamabad',
      destination: destination,
      category: 'City Ride',
      driverName: 'Ahmed',
      vehicle: 'Toyota Corolla',
      farePkr: 650,
      completedAt: DateTime(2026, 10, 29),
    );
  }

  setUp(() {
    store = RiderRideHistoryStore();
  });

  tearDown(() {
    store.dispose();
  });

  test('starts with empty history', () {
    expect(store.completedRides, isEmpty);
  });

  test('records a completed ride', () {
    final added = store.recordCompletedRide(
      tripKey: Object(),
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    expect(added, isTrue);
    expect(store.completedRides.length, 1);
    expect(store.completedRides.first.farePkr, 650);
  });

  test('does not duplicate the same trip', () {
    final key = Object();

    store.recordCompletedRide(
      tripKey: key,
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    final addedAgain = store.recordCompletedRide(
      tripKey: key,
      ride: sampleRide('F-10 Markaz, Islamabad'),
    );

    expect(addedAgain, isFalse);
    expect(store.completedRides.length, 1);
  });

  test('newest recorded ride appears first', () {
    store.recordCompletedRide(
      tripKey: Object(),
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    store.recordCompletedRide(
      tripKey: Object(),
      ride: sampleRide('F-10 Markaz, Islamabad'),
    );

    expect(store.completedRides.first.destination, 'F-10 Markaz, Islamabad');
  });

  test('notifies listeners when a ride is added', () {
    var notifications = 0;
    store.addListener(() => notifications++);

    store.recordCompletedRide(
      tripKey: Object(),
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    expect(notifications, 1);
  });

  test('duplicate recording does not notify listeners', () {
    final key = Object();
    var notifications = 0;
    store.addListener(() => notifications++);

    store.recordCompletedRide(
      tripKey: key,
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    store.recordCompletedRide(
      tripKey: key,
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    expect(notifications, 1);
  });

  test('clear removes all history', () {
    store.recordCompletedRide(
      tripKey: Object(),
      ride: sampleRide('Faisal Mosque, Islamabad'),
    );

    store.clear();

    expect(store.completedRides, isEmpty);
  });
}
