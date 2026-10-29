
import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/features/rider/account/rider_profile_store.dart';

void main() {
  late RiderProfileStore store;

  setUp(() {
    store = RiderProfileStore();
  });

  tearDown(() {
    store.dispose();
  });

  test('starts with the existing mock profile', () {
    expect(store.profile.fullName, 'Ali');
    expect(store.profile.firstName, 'Ali');
    expect(
      store.profile.phoneNumber,
      '+92 300 1234567',
    );
  });

  test('updates full name and email', () {
    store.updateProfile(
      fullName: 'Ahmad Khan',
      email: 'ahmad@example.com',
    );

    expect(store.profile.fullName, 'Ahmad Khan');
    expect(store.profile.firstName, 'Ahmad');
    expect(store.profile.email, 'ahmad@example.com');
  });

  test('preserves the verified phone number', () {
    final oldPhone = store.profile.phoneNumber;

    store.updateProfile(
      fullName: 'Ahmad Khan',
      email: '',
    );

    expect(store.profile.phoneNumber, oldPhone);
  });

  test('rejects an empty full name', () {
    expect(
      () => store.updateProfile(
        fullName: '   ',
        email: '',
      ),
      throwsArgumentError,
    );
  });

  test('rejects an invalid email', () {
    expect(
      () => store.updateProfile(
        fullName: 'Ahmad',
        email: 'invalid-email',
      ),
      throwsArgumentError,
    );
  });

  test('allows optional email', () {
    store.updateProfile(
      fullName: 'Ahmad',
      email: '',
    );

    expect(store.profile.email, '');
  });

  test('notifies listeners after changes', () {
    var notificationCount = 0;

    void listener() {
      notificationCount++;
    }

    store.addListener(listener);

    store.updateProfile(
      fullName: 'Ahmad',
      email: 'ahmad@example.com',
    );

    expect(notificationCount, 1);

    store.removeListener(listener);
  });
}
