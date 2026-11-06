import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../../auth/auth_session.dart';
import 'rider_profile_store.dart';
import 'email_verification_dialog.dart';

const _profileBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFF2EDFF), Colors.white, Color(0xFFEDF4FF)],
    stops: [0, 0.52, 1],
  ),
);

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: riderProfileStore,
      builder: (context, _) {
        final profile = riderProfileStore.profile;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF2EDFF),
            title: const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.navy,
              ),
            ),
          ),
          body: Container(
            decoration: _profileBackground,
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  _ProfileHeader(fullName: profile.fullName),

                  const SizedBox(height: 24),

                  _InformationCard(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: profile.fullName,
                  ),

                  const SizedBox(height: 10),

                  _InformationCard(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: profile.phoneNumber,
                    locked: true,
                  ),

                  const SizedBox(height: 10),

                  _InformationCard(
                    icon: Icons.mail_outline,
                    label: 'Email Address',
                    value: profile.email.isEmpty
                        ? 'Not provided'
                        : profile.email,
                  ),

                  if (profile.email.isNotEmpty)
                    Text(profile.emailVerified ? 'Verified' : 'Unverified'),
                  if (profile.pendingEmail.isNotEmpty)
                    Text('Awaiting verification for ${profile.pendingEmail}'),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => EmailVerificationDialog(profile: profile),
                    ),
                    child: Text(
                      profile.emailVerified ? 'Change email' : 'Verify email',
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: HiGoTheme.secondaryText,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your phone number is managed '
                          'securely and cannot be '
                          'changed here.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  _PrimaryAction(
                    label: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context) {
    final initial = fullName.isEmpty ? '?' : fullName[0].toUpperCase();

    return Column(
      children: [
        CircleAvatar(
          radius: 49,
          backgroundColor: const Color(0xFFEDEAFF),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFDCD6FF),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: HiGoTheme.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFECFF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 17, color: HiGoTheme.primary),
              SizedBox(width: 7),
              Text(
                'Rider',
                style: TextStyle(
                  fontSize: 13,
                  color: HiGoTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.label,
    required this.value,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: HiGoTheme.primary, size: 23),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: HiGoTheme.secondaryText,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: locked ? HiGoTheme.secondaryText : HiGoTheme.navy,
                  ),
                ),
              ],
            ),
          ),

          if (locked)
            const Icon(
              Icons.lock_outline,
              size: 19,
              color: HiGoTheme.secondaryText,
            ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7964F6), Color(0xFF458FF1)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final RiderProfile _initialProfile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _initialProfile = riderProfileStore.profile;

    _nameController = TextEditingController(text: _initialProfile.fullName);

    _emailController = TextEditingController(text: _initialProfile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      await riderProfileStore.updateProfile(
        fullName: name == _initialProfile.fullName ? null : name,
        email: email == _initialProfile.email ? null : email,
      );
      if (mounted && ModalRoute.isCurrentOf(context) == true) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted || ModalRoute.isCurrentOf(context) != true) return;
      final messenger = ScaffoldMessenger.of(context);
      if (error is AuthError &&
          error.status == 401 &&
          !authSession.authenticated) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = riderProfileStore.profile;

    final page = Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2EDFF),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),
      ),
      body: Container(
        decoration: _profileBackground,
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                _ProfileHeader(fullName: profile.fullName),

                const SizedBox(height: 25),

                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (utf8.encode(value.trim()).length > 150) {
                      return 'Enter a shorter name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _emailController,
                  enabled: !_saving && !_initialProfile.emailVerified,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty || email == _initialProfile.email) {
                      return null;
                    }
                    if (utf8.encode(email).length > 254) {
                      return 'Enter a shorter email address';
                    }

                    final valid = RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(email);

                    return valid ? null : 'Enter a valid email address';
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  initialValue: profile.phoneNumber,
                  readOnly: true,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    suffixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Changing your phone number requires verification.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: HiGoTheme.secondaryText,
                  ),
                ),

                const SizedBox(height: 26),

                _PrimaryAction(
                  label: _saving ? 'Saving…' : 'Save Changes',
                  icon: Icons.check,
                  onPressed: _saving ? null : _saveProfile,
                ),

                const SizedBox(height: 10),

                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return PopScope(canPop: !_saving, child: page);
  }
}
