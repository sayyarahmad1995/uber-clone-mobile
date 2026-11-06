import 'package:flutter/foundation.dart';

import '../features/auth/auth_session.dart';

enum HiGoAppMode { rider, driver }

class AppModeController extends ValueNotifier<HiGoAppMode> {
  AppModeController(this.session) : super(HiGoAppMode.rider) {
    session.addListener(_updateAccount);
    _updateAccount();
  }

  final AuthSession session;
  Object? _account;

  bool get canUseDriverMode {
    final capabilities = session.user?['capabilities'];
    return capabilities is List && capabilities.contains('driver');
  }

  void _updateAccount() {
    final account = session.user?['id'];
    if (account != _account || !canUseDriverMode) {
      value = HiGoAppMode.rider;
    }
    _account = account;
  }

  void switchToDriver() {
    if (canUseDriverMode) value = HiGoAppMode.driver;
  }

  void switchToRider() => value = HiGoAppMode.rider;

  @override
  void dispose() {
    session.removeListener(_updateAccount);
    super.dispose();
  }
}

final appMode = AppModeController(authSession);

void switchToRiderMode() => appMode.switchToRider();
