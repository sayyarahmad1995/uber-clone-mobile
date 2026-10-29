import 'package:flutter/foundation.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.pushNotifications = true,
    this.tripUpdates = true,
    this.promotionalNotifications = false,
  });

  final bool pushNotifications;
  final bool tripUpdates;
  final bool promotionalNotifications;

  AppSettings copyWith({
    bool? pushNotifications,
    bool? tripUpdates,
    bool? promotionalNotifications,
  }) {
    return AppSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      tripUpdates: tripUpdates ?? this.tripUpdates,
      promotionalNotifications:
          promotionalNotifications ?? this.promotionalNotifications,
    );
  }
}

class AppSettingsStore extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  void setPushNotifications(bool enabled) {
    if (_settings.pushNotifications == enabled) return;

    _settings = _settings.copyWith(pushNotifications: enabled);
    notifyListeners();
  }

  void setTripUpdates(bool enabled) {
    if (_settings.tripUpdates == enabled) return;

    _settings = _settings.copyWith(tripUpdates: enabled);
    notifyListeners();
  }

  void setPromotionalNotifications(bool enabled) {
    if (_settings.promotionalNotifications == enabled) {
      return;
    }

    _settings = _settings.copyWith(promotionalNotifications: enabled);
    notifyListeners();
  }

  void reset() {
    _settings = const AppSettings();
    notifyListeners();
  }
}

final appSettingsStore = AppSettingsStore();
