import 'package:flutter_test/flutter_test.dart';
import 'package:uberclone/features/account/app_settings_store.dart';

void main() {
  late AppSettingsStore store;

  setUp(() {
    store = AppSettingsStore();
  });

  tearDown(() {
    store.dispose();
  });

  group('AppSettingsStore', () {
    test('starts with expected defaults', () {
      expect(store.settings.pushNotifications, isTrue);
      expect(store.settings.tripUpdates, isTrue);
      expect(store.settings.promotionalNotifications, isFalse);
    });

    test('updates push notifications', () {
      store.setPushNotifications(false);

      expect(store.settings.pushNotifications, isFalse);
    });

    test('updates trip notifications', () {
      store.setTripUpdates(false);

      expect(store.settings.tripUpdates, isFalse);
    });

    test('updates promotional notifications', () {
      store.setPromotionalNotifications(true);

      expect(store.settings.promotionalNotifications, isTrue);
    });

    test('notifies listeners when a value changes', () {
      var notifications = 0;

      store.addListener(() {
        notifications++;
      });

      store.setPushNotifications(false);

      expect(notifications, 1);
    });

    test('does not notify listeners for unchanged values', () {
      var notifications = 0;

      store.addListener(() {
        notifications++;
      });

      store.setPushNotifications(true);
      store.setTripUpdates(true);
      store.setPromotionalNotifications(false);

      expect(notifications, 0);
    });

    test('preserves other preferences when one changes', () {
      store.setPromotionalNotifications(true);
      store.setTripUpdates(false);

      expect(store.settings.pushNotifications, isTrue);
      expect(store.settings.tripUpdates, isFalse);
      expect(store.settings.promotionalNotifications, isTrue);
    });

    test('reset restores the original defaults', () {
      store.setPushNotifications(false);
      store.setTripUpdates(false);
      store.setPromotionalNotifications(true);

      store.reset();

      expect(store.settings.pushNotifications, isTrue);
      expect(store.settings.tripUpdates, isTrue);
      expect(store.settings.promotionalNotifications, isFalse);
    });
  });
}
