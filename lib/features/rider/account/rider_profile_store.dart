import 'package:flutter/foundation.dart';

import '../../auth/auth_session.dart';

@immutable
class RiderProfile {
  const RiderProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.emailVerified = false,
    this.pendingEmail = '',
  });

  final String fullName;
  final String phoneNumber;
  final String email;
  final bool emailVerified;
  final String pendingEmail;

  String get firstName {
    final name = fullName.trim();

    if (name.isEmpty) return '';

    return name.split(RegExp(r'\s+')).first;
  }
}

/// The signed-in account is the only profile cache.
class RiderProfileStore implements Listenable {
  RiderProfileStore(this._session);

  final AuthSession _session;

  RiderProfile get profile {
    final user = _session.user;
    return RiderProfile(
      fullName: user?['name'] as String? ?? '',
      phoneNumber: user?['phone'] as String? ?? '',
      email: user?['email'] as String? ?? '',
      emailVerified: user?['email_verified'] == true,
      pendingEmail: user?['pending_email'] as String? ?? '',
    );
  }

  Future<void> updateProfile({String? fullName, String? email}) =>
      _session.updateProfile(name: fullName, email: email);

  @override
  void addListener(VoidCallback listener) => _session.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _session.removeListener(listener);
}

final riderProfileStore = RiderProfileStore(authSession);
