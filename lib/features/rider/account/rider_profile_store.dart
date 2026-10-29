import 'package:flutter/foundation.dart';

/// Mock rider profile data.
///
/// Replace with data from the Go backend when
/// real API integration begins.
@immutable
class RiderProfile {
  const RiderProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
  });

  final String fullName;
  final String phoneNumber;
  final String email;

  String get firstName {
    final name = fullName.trim();

    if (name.isEmpty) return '';

    return name.split(RegExp(r'\s+')).first;
  }
}

/// Lightweight, in-memory mock state.
///
/// No third-party state-management package.
class RiderProfileStore extends ChangeNotifier {
  RiderProfile _profile = const RiderProfile(
    fullName: 'Ali',
    phoneNumber: '+92 300 1234567',
    email: 'ali@example.com',
  );

  RiderProfile get profile => _profile;

  void updateProfile({required String fullName, required String email}) {
    final name = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');

    final cleanedEmail = email.trim();

    if (name.isEmpty) {
      throw ArgumentError('Full name is required.');
    }

    if (cleanedEmail.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanedEmail)) {
      throw ArgumentError('Invalid email address.');
    }

    _profile = RiderProfile(
      fullName: name,
      phoneNumber: _profile.phoneNumber,
      email: cleanedEmail,
    );

    notifyListeners();
  }
}

/// Shared mock profile for Rider screens.
final riderProfileStore = RiderProfileStore();
