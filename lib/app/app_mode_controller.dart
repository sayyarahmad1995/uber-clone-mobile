import 'package:flutter/foundation.dart';

enum HiGoAppMode { rider, driver }

// Development-only mode controller.
//
// Later, driver access will depend on the authenticated
// user's approved driver capability.
final ValueNotifier<HiGoAppMode> hiGoAppMode = ValueNotifier<HiGoAppMode>(
  HiGoAppMode.driver,
);

void switchToRiderMode() {
  hiGoAppMode.value = HiGoAppMode.rider;
}

void switchToDriverMode() {
  hiGoAppMode.value = HiGoAppMode.driver;
}
