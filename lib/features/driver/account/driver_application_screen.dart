import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/higo_theme.dart';
import '../../auth/auth_session.dart';
import 'driver_document_picker.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({
    super.key,
    this.session,
    this.pickDocument,
    this.captureSelfie,
  });

  final AuthSession? session;
  final Future<Uint8List?> Function(int maxBytes)? pickDocument;
  final Future<Uint8List?> Function(int maxBytes)? captureSelfie;

  @override
  State<DriverApplicationScreen> createState() =>
      _DriverApplicationScreenState();
}

const _steps = [
  'Driver Details',
  'Vehicle Details',
  'Upload Documents',
  'Review & Submit',
];
const _vehicle = {
  'make': ('Vehicle Make', 'e.g. Toyota'),
  'model': ('Vehicle Model', 'e.g. Corolla'),
  'manufacture_year': ('Manufacturing Year', 'e.g. 2022'),
  'color': ('Vehicle Color', 'e.g. White'),
  'registration_number': ('Registration Number', 'e.g. ABC-123'),
};
const _groups = {
  'Identity documents': {'cnic_front': 'CNIC Front', 'cnic_back': 'CNIC Back'},
  'Driving license': {
    'license_front': 'Driving License Front',
    'license_back': 'Driving License Back',
  },
  'Vehicle documents': {
    'registration': 'Vehicle Registration',
    'additional': 'Additional Vehicle Document',
  },
  'Vehicle exterior photographs': {
    'exterior_front': 'Vehicle Front — Exterior',
    'exterior_rear': 'Vehicle Rear — Exterior',
    'exterior_right': 'Vehicle Right — Exterior',
    'exterior_left': 'Vehicle Left — Exterior',
  },
  'Vehicle interior photographs': {
    'interior_front': 'Vehicle Front — Interior',
    'interior_rear': 'Vehicle Rear — Interior',
  },
};

DateTime _todayInPakistan() =>
    DateUtils.dateOnly(DateTime.now().toUtc().add(const Duration(hours: 5)));

String _dateString(DateTime date) => date.toIso8601String().split('T').first;
String _cnicFormat(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final a = digits.substring(0, digits.length.clamp(0, 5));
  final b = digits.length > 5
      ? '-${digits.substring(5, digits.length.clamp(5, 12))}'
      : '';
  final c = digits.length > 12 ? '-${digits.substring(12)}' : '';
  return '$a$b$c';
}

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  AuthSession get _session => widget.session ?? authSession;
  late final Object? _owner = _session.user?['id'];
  var _form = GlobalKey<FormState>();
  final _draft = <String, String>{};
  final _saved = <String>{};
  MemoryImage? _selfie;
  Uint8List? _pendingImage;
  String? _pendingKind;
  String? _uploading;
  String? _error;
  bool _loaded = false;
  bool _busy = false;
  bool _conflict = false;
  bool _underReview = false;
  bool _confirmed = false;
  int _step = 0;

  bool get _sameAccount => _owner != null && _session.user?['id'] == _owner;
  String get _phone => _session.user?['phone'] as String? ?? 'Unavailable';
  String get _email {
    final value = _session.user?['email'] as String?;
    if (value == null || value.isEmpty) return 'Not provided';
    return '$value (${_session.user?['email_verified'] == true ? 'verified' : 'unverified'})';
  }

  @override
  void initState() {
    super.initState();
    _session.addListener(_accountChanged);
    _load();
  }

  void _setSelfie(Uint8List? bytes) {
    if (_selfie case final old?) unawaited(old.evict());
    _selfie = bytes == null ? null : MemoryImage(bytes);
  }

  void _accountChanged() {
    if (_sameAccount) return;
    setState(() {
      _draft.clear();
      _saved.clear();
      _setSelfie(null);
      _pendingImage = null;
      _pendingKind = null;
      _loaded = false;
    });
  }

  @override
  void dispose() {
    _session.removeListener(_accountChanged);
    _setSelfie(null);
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_sameAccount) return;
    setState(() {
      _busy = true;
      _error = null;
      _conflict = false;
    });
    try {
      await action();
    } catch (error) {
      if (mounted && _sameAccount) {
        _conflict = error is AuthError && error.code == 'onboarding_conflict';
        _error = _conflict
            ? 'The saved application changed. Refresh to load the latest draft.'
            : authErrorMessage(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _uploading = null;
        });
      }
    }
  }

  void _adopt(Map<String, dynamic> application) {
    final draft = application['draft'] as Map;
    _draft
      ..clear()
      ..addAll(draft.cast<String, String>());
    _saved
      ..clear()
      ..addAll(
        (application['documents'] as List? ?? const []).whereType<String>(),
      );
    _underReview = application['status'] == 'pending_review';
    _loaded = true;
  }

  Future<Uint8List> _fetchPreview(String kind) async {
    final response = await _session.driverApplicationPreview(
      accountId: _owner,
      kind: kind,
    );
    return base64Decode(response['image'] as String);
  }

  Future<void> _load() => _run(() async {
    final application = await _session.driverApplication(accountId: _owner);
    if (!mounted || !_sameAccount) return;
    _adopt(application);
    _draft.putIfAbsent(
      'legal_name',
      () => _session.user?['name'] as String? ?? '',
    );
    _step = (int.tryParse(_draft['step'] ?? '') ?? 0).clamp(0, 3);
    _form = GlobalKey<FormState>();
    _setSelfie(null);
    _pendingImage = null;
    _pendingKind = null;
    _confirmed = false;
    if (!_underReview && _saved.contains('selfie')) {
      try {
        final selfie = await _fetchPreview('selfie');
        if (mounted && _sameAccount) _setSelfie(selfie);
      } on AuthError {
        // The saved selfie stays attached if the preview request fails.
      }
    }
  });

  Future<void> _persist(int step) async {
    final updated = await _session.saveDriverApplicationDraft({
      ..._draft,
      'step': '$step',
    }, accountId: _owner);
    if (mounted && _sameAccount) _adopt(updated);
  }

  Future<void> _send(String kind, Uint8List bytes) async {
    setState(() => _uploading = kind);
    final response = await _session.saveDriverApplicationDocument({
      'draft_revision': _draft['revision']!,
      'kind': kind,
      'image': base64Encode(bytes),
    }, accountId: _owner);
    if (mounted && _sameAccount) _adopt(response);
  }

  Future<void> _next() => _run(() async {
    if (!(_form.currentState?.validate() ?? true)) return;
    _form.currentState?.save();
    if (_step == 0 && _pendingKind == 'selfie' && _pendingImage != null) {
      // A new draft gets a revision before its first camera upload.
      await _persist(0);
      if (!mounted || !_sameAccount) return;
      await _send('selfie', _pendingImage!);
      if (!mounted || !_sameAccount) return;
      _pendingImage = null;
      _pendingKind = null;
    }
    if (_step == 0 && !_saved.contains('selfie')) {
      _error = 'Take a selfie before continuing.';
      return;
    }
    if (_step == 2 && (!_documentsComplete || _pendingKind != null)) {
      _error = _pendingKind != null
          ? 'Save or cancel the selected image before continuing.'
          : 'Save all required images before continuing.';
      return;
    }
    await _persist(_step + 1);
    if (!mounted || !_sameAccount) return;
    _step++;
    _form = GlobalKey<FormState>();
    _confirmed = false;
  });

  Future<void> _goTo(int step) => _run(() async {
    if (_step == 2) _form.currentState?.save();
    await _persist(step);
    if (!mounted || !_sameAccount) return;
    _step = step;
    _pendingImage = null;
    _pendingKind = null;
    _form = GlobalKey<FormState>();
    _confirmed = false;
  });

  Future<void> _saveAndExit() => _run(() async {
    _form.currentState?.save();
    if (_step < 3) await _persist(_step);
    if (mounted && _sameAccount) Navigator.of(context).pop();
  });

  Future<void> _submit() => _run(() async {
    if (!_confirmed || !_reviewReady) return;
    final application = await _session.submitDriverApplication(
      accountId: _owner,
      draftRevision: _draft['revision']!,
    );
    if (!mounted || !_sameAccount) return;
    _adopt(application);
    _setSelfie(null);
    _pendingImage = null;
    _pendingKind = null;
  });

  bool get _documentsComplete =>
      _saved.contains('selfie') &&
      _groups.values
          .expand((group) => group.keys)
          .where((kind) => kind != 'additional')
          .every(_saved.contains);

  bool get _reviewReady {
    bool current(String key) {
      final date = DateTime.tryParse(_draft[key] ?? '');
      return date != null && !date.isBefore(_todayInPakistan());
    }

    bool valid(String key, String noExpiry) =>
        switch (_draft['${key}_validity']) {
          'expires' => current('${key}_expiry'),
          final value => value == noExpiry,
        };
    return _documentsComplete &&
        valid('cnic', 'lifetime') &&
        current('license_expiry') &&
        valid('registration', 'no_expiry') &&
        (!_saved.contains('additional') || valid('additional', 'no_expiry'));
  }

  Future<void> _choose(String kind) => _run(() async {
    final selfie = kind == 'selfie';
    final max = kind.startsWith('cnic_')
        ? identityDocumentMaxBytes
        : vehicleDocumentMaxBytes;
    final pick = selfie
        ? widget.captureSelfie ?? captureDriverSelfie
        : widget.pickDocument ?? pickDriverDocument;
    final selected = await pick(max);
    if (selected == null || !mounted || !_sameAccount) return;
    final bytes = await prepareDriverDocument(selected, max);
    if (!mounted || !_sameAccount) return;
    _pendingImage = bytes;
    _pendingKind = kind;
    if (selfie) _setSelfie(bytes);
  });

  Future<void> _saveSelected(String kind) => _run(() async {
    final bytes = _pendingImage;
    if (_pendingKind != kind || bytes == null) return;
    // Keep unsaved expiry edits while the server advances the upload revision.
    final validity = Map<String, String>.fromEntries(
      _draft.entries.where(
        (entry) =>
            entry.key.endsWith('_validity') || entry.key.endsWith('_expiry'),
      ),
    );
    await _send(kind, bytes);
    if (!mounted || !_sameAccount) return;
    _draft.removeWhere(
      (key, _) => key.endsWith('_validity') || key.endsWith('_expiry'),
    );
    _draft.addAll(validity);
    _pendingKind = null;
    _pendingImage = null;
  });

  Future<void> _removeAdditional() => _run(() async {
    final validity = Map<String, String>.fromEntries(
      _draft.entries.where(
        (entry) =>
            (entry.key.endsWith('_validity') ||
                entry.key.endsWith('_expiry')) &&
            !entry.key.startsWith('additional_'),
      ),
    );
    final response = await _session.removeAdditionalDriverDocument(
      accountId: _owner,
      draftRevision: _draft['revision']!,
    );
    if (!mounted || !_sameAccount) return;
    _adopt(response);
    _draft.addAll(validity);
    if (_pendingKind == 'additional') {
      _pendingKind = null;
      _pendingImage = null;
    }
  });

  Future<void> _preview(String kind, String title) => _run(() async {
    final bytes = _pendingKind == kind
        ? _pendingImage
        : await _fetchPreview(kind);
    if (bytes == null || !mounted || !_sameAccount) return;
    final image = MemoryImage(bytes);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: ListenableBuilder(
            listenable: _session,
            builder: (context, _) => _sameAccount
                ? Image(image: image, fit: BoxFit.contain)
                : const SizedBox.shrink(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      await image.evict();
    }
  });

  Widget _field(
    String key,
    String label,
    String hint, {
    String? Function(String)? validate,
    bool number = false,
    bool cnic = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      initialValue: cnic ? _cnicFormat(_draft[key] ?? '') : _draft[key],
      enabled: !_busy,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      textCapitalization: TextCapitalization.words,
      inputFormatters: cnic
          ? [
              TextInputFormatter.withFunction((old, value) {
                final digits = value.text.replaceAll(RegExp(r'\D'), '');
                if (digits.length > 13) return old;
                final formatted = _cnicFormat(digits);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'This field is required.';
        return validate?.call(text);
      },
      onSaved: (value) => _draft[key] = cnic
          ? (value ?? '').replaceAll(RegExp(r'\D'), '')
          : (value ?? '').trim(),
    ),
  );

  Widget _date(String key, String label, {bool birth = false}) {
    final now = _todayInPakistan();
    final first = birth ? DateTime(1900) : now;
    final birthYear = now.year - 18;
    final lastBirthDay = DateTime(birthYear, now.month + 1, 0).day;
    final last = birth
        ? DateTime(birthYear, now.month, now.day.clamp(1, lastBirthDay))
        : DateTime(now.year + 50, 12, 31);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormField<String>(
        key: ValueKey(key),
        initialValue: _draft[key],
        validator: (value) {
          final parsed = DateTime.tryParse(value ?? '');
          if (parsed == null) return 'Choose a date.';
          if (parsed.isBefore(first) || parsed.isAfter(last)) {
            return birth
                ? 'You must be at least 18 to apply.'
                : 'Choose a date that has not expired.';
          }
          return null;
        },
        onSaved: (value) => _draft[key] = value ?? '',
        builder: (field) => InkWell(
          key: ValueKey('date-$key'),
          borderRadius: BorderRadius.circular(14),
          onTap: _busy
              ? null
              : () async {
                  final date = DateTime.tryParse(field.value ?? '');
                  final selected = await showDatePicker(
                    context: context,
                    initialDate:
                        date != null &&
                            !date.isBefore(first) &&
                            !date.isAfter(last)
                        ? date
                        : (birth ? last : first),
                    firstDate: first,
                    lastDate: last,
                    switchToInputEntryModeIcon: const Icon(Icons.edit_outlined),
                  );
                  if (selected != null && field.mounted && _sameAccount) {
                    final value = _dateString(selected);
                    _draft[key] = value;
                    field.didChange(value);
                  }
                },
          child: InputDecorator(
            isEmpty: field.value == null || field.value!.isEmpty,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(field.value ?? ''),
          ),
        ),
      ),
    );
  }

  Widget _validity(
    String key,
    String label,
    String noExpiry,
    String noExpiryLabel,
  ) {
    final value = _draft['${key}_validity'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('validity-$key'),
        initialValue: value == 'expires' || value == noExpiry ? value : null,
        decoration: InputDecoration(labelText: label, filled: true),
        items: [
          const DropdownMenuItem(
            value: 'expires',
            child: Text('Has an expiry date'),
          ),
          DropdownMenuItem(value: noExpiry, child: Text(noExpiryLabel)),
        ],
        validator: (value) =>
            value == null ? 'Choose the validity shown on the document.' : null,
        onChanged: _busy
            ? null
            : (value) => setState(() {
                _draft['${key}_validity'] = value!;
                if (value != 'expires') _draft.remove('${key}_expiry');
              }),
      ),
    );
  }

  Widget _selfieCard() => _Card(
    children: [
      const Text('Selfie', style: _cardTitle),
      const SizedBox(height: 8),
      if (_selfie case final image?)
        Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: image,
              height: 104,
              width: 104,
              fit: BoxFit.cover,
            ),
          ),
        ),
      Text(
        _uploading == 'selfie'
            ? 'Uploading…'
            : _pendingKind == 'selfie'
            ? 'Selected'
            : _saved.contains('selfie')
            ? 'Saved'
            : 'Take a clear photo using your camera.',
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _choose('selfie'),
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(
          _selfie == null && !_saved.contains('selfie')
              ? 'Take selfie'
              : 'Retake selfie',
        ),
      ),
      if (_selfie == null && _saved.contains('selfie'))
        TextButton(
          onPressed: _busy ? null : () => _preview('selfie', 'Selfie'),
          child: const Text('Preview selfie'),
        ),
    ],
  );

  List<Widget> _driver() => [
    _selfieCard(),
    const SizedBox(height: 16),
    _field(
      'legal_name',
      'Legal Name',
      'As shown on your CNIC',
      validate: (value) =>
          utf8.encode(value).length > 150 ? 'Use up to 150 UTF-8 bytes.' : null,
    ),
    _date('date_of_birth', 'Date of Birth', birth: true),
    _field(
      'cnic_number',
      'CNIC Number',
      '12345-1234567-1',
      number: true,
      cnic: true,
      validate: (value) => value.replaceAll(RegExp(r'\D'), '').length != 13
          ? 'Enter all 13 CNIC digits.'
          : null,
    ),
    _readOnly('Phone Number', _phone),
    _readOnly('Email Address (optional)', _email),
  ];

  Widget _readOnly(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        suffixIcon: const Icon(Icons.lock_outline),
      ),
      child: Text(value),
    ),
  );

  String? _validateVehicle(String key, String value) {
    if (key == 'manufacture_year') {
      final year = int.tryParse(value);
      if (year == null || year < 1900 || year > DateTime.now().year + 1) {
        return 'Enter a valid manufacturing year.';
      }
    } else if (key == 'registration_number') {
      if (!RegExp(
        r'^[A-Z0-9][A-Z0-9 -]{1,23}$',
      ).hasMatch(value.toUpperCase())) {
        return 'Enter 2 to 24 letters, numbers, spaces or hyphens.';
      }
    } else if (utf8.encode(value).length > 80) {
      return 'Use up to 80 UTF-8 bytes.';
    }
    return null;
  }

  Widget _documentCard(String kind, String label) {
    final saved = _saved.contains(kind);
    final selected = _pendingKind == kind;
    final status = _uploading == kind
        ? 'Uploading…'
        : selected
        ? 'Selected'
        : saved
        ? 'Saved'
        : 'Missing';
    return _Card(
      children: [
        Row(
          children: [
            Icon(
              saved ? Icons.check_circle_outline : Icons.upload_file_outlined,
              color: saved ? const Color(0xFF15803D) : HiGoTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                kind == 'additional' ? '$label (optional)' : label,
                style: _cardTitle,
              ),
            ),
            Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                color: HiGoTheme.secondaryText,
              ),
            ),
          ],
        ),
        Text(
          kind.startsWith('cnic_')
              ? 'JPEG or PNG · up to 1 MB'
              : 'JPEG or PNG · up to 2 MB',
          style: const TextStyle(fontSize: 11, color: HiGoTheme.secondaryText),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _busy ? null : () => _choose(kind),
              child: Text(
                saved || selected ? 'Replace $label' : 'Choose $label',
              ),
            ),
            if (saved || selected)
              TextButton(
                onPressed: _busy ? null : () => _preview(kind, label),
                child: Text('Preview $label'),
              ),
            if (kind == 'additional' && saved)
              TextButton(
                onPressed: _busy ? null : _removeAdditional,
                child: const Text('Remove additional document'),
              ),
            if (selected)
              FilledButton(
                onPressed: _busy ? null : () => _saveSelected(kind),
                child: Text('Save $label'),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _documentStep() => [
    for (final group in _groups.entries) ...[
      Text(group.key, style: _cardTitle),
      const SizedBox(height: 8),
      for (final document in group.value.entries) ...[
        _documentCard(document.key, document.value),
        const SizedBox(height: 10),
      ],
      if (group.key == 'Identity documents') ...[
        _validity('cnic', 'CNIC Validity', 'lifetime', 'Lifetime'),
        if (_draft['cnic_validity'] == 'expires')
          _date('cnic_expiry', 'CNIC Expiry Date'),
      ],
      if (group.key == 'Driving license')
        _date('license_expiry', 'License Expiry Date'),
      if (group.key == 'Vehicle documents') ...[
        _validity(
          'registration',
          'Registration Validity',
          'no_expiry',
          'No expiry',
        ),
        if (_draft['registration_validity'] == 'expires')
          _date('registration_expiry', 'Registration Expiry Date'),
        if (_saved.contains('additional') || _pendingKind == 'additional') ...[
          _validity(
            'additional',
            'Additional Document Validity',
            'no_expiry',
            'No expiry',
          ),
          if (_draft['additional_validity'] == 'expires')
            _date('additional_expiry', 'Additional Document Expiry Date'),
        ],
      ],
      const SizedBox(height: 12),
    ],
  ];

  String _validitySummary(String key) => switch (_draft['${key}_validity']) {
    'lifetime' => 'Lifetime',
    'no_expiry' => 'No expiry',
    _ => _draft['${key}_expiry'] ?? 'Missing',
  };

  List<Widget> _review() {
    final number = _draft['cnic_number'] ?? '';
    final masked = number.length == 13
        ? '•••••-••••${number.substring(9, 12)}-${number[12]}'
        : 'Missing';
    return [
      _Card(
        children: [
          _summaryTitle('Driver Details', 0),
          if (_selfie case final image?)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: image,
                height: 82,
                width: 82,
                fit: BoxFit.cover,
              ),
            )
          else if (_saved.contains('selfie'))
            TextButton(
              onPressed: _busy ? null : () => _preview('selfie', 'Selfie'),
              child: const Text('Preview selfie'),
            ),
          _row('Legal Name', _draft['legal_name'] ?? ''),
          _row('Date of Birth', _draft['date_of_birth'] ?? ''),
          _row('CNIC Number', masked),
          _row('Phone Number', _phone),
          _row('Email Address', _email),
        ],
      ),
      const SizedBox(height: 12),
      _Card(
        children: [
          _summaryTitle('Vehicle Details', 1),
          for (final field in _vehicle.entries)
            _row(field.value.$1, _draft[field.key] ?? ''),
        ],
      ),
      const SizedBox(height: 12),
      _Card(
        children: [
          _summaryTitle('Documents', 2),
          for (final group in _groups.entries) ...[
            Text(group.key, style: _cardTitle),
            for (final item in group.value.entries)
              _row(
                item.value,
                _saved.contains(item.key)
                    ? 'Saved'
                    : item.key == 'additional'
                    ? 'Not provided'
                    : 'Missing',
              ),
            const SizedBox(height: 8),
          ],
          _row('CNIC Validity', _validitySummary('cnic')),
          _row('License Expiry', _draft['license_expiry'] ?? 'Missing'),
          _row('Registration Validity', _validitySummary('registration')),
          if (_saved.contains('additional'))
            _row(
              'Additional Document Validity',
              _validitySummary('additional'),
            ),
        ],
      ),
      if (!_reviewReady)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Check that all required images and expiry dates are still valid before submitting.',
          ),
        ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _confirmed,
        onChanged: _busy
            ? null
            : (value) => setState(() => _confirmed = value ?? false),
        title: const Text('I confirm the details and documents are accurate.'),
      ),
    ];
  }

  Widget _summaryTitle(String title, int step) => Row(
    children: [
      Expanded(child: Text(title, style: _cardTitle)),
      TextButton(
        onPressed: _busy ? null : () => _goTo(step),
        child: Text('Edit $title'),
      ),
    ],
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: HiGoTheme.secondaryText,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: HiGoTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wizard = _loaded && !_underReview && _sameAccount;
    return PopScope(
      canPop: !_busy && (!wizard || _step == 0),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && wizard && !_busy && _step > 0) {
          unawaited(_goTo(_step - 1));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _underReview ? 'Application Pending Review' : 'Driver Application',
          ),
          actions: [
            if (wizard)
              TextButton(
                onPressed: _busy ? null : _saveAndExit,
                child: const Text('Save & exit'),
              ),
          ],
          leading: wizard && _step > 0
              ? BackButton(onPressed: _busy ? null : () => _goTo(_step - 1))
              : null,
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFF2EDFF),
                Colors.white,
                Colors.white,
                Color(0xFFEDF4FF),
              ],
              stops: [0, .27, .74, 1],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (wizard) _Progress(step: _step),
                if (_busy) const LinearProgressIndicator(),
                Expanded(
                  child: ListView(
                    key: ValueKey(_underReview ? 'submitted' : _step),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      if (_error case final error?)
                        Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      if (_conflict)
                        TextButton(
                          onPressed: _load,
                          child: const Text('Refresh application'),
                        ),
                      if (!_sameAccount)
                        const Text('Sign in to view your driver application.')
                      else if (_underReview) ...[
                        const SizedBox(height: 48),
                        const Icon(
                          Icons.check_circle,
                          size: 72,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your application has been submitted for review.',
                          textAlign: TextAlign.center,
                        ),
                      ] else if (wizard) ...[
                        Text(
                          _steps[_step],
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          const [
                            'Tell us about yourself and take a selfie.',
                            'Enter the details of the vehicle you will drive.',
                            'Add clear photos of your documents and vehicle.',
                            'Check your information before sending it for review.',
                          ][_step],
                          style: const TextStyle(
                            fontSize: 13,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: switch (_step) {
                              0 => _driver(),
                              1 => [
                                for (final field in _vehicle.entries)
                                  _field(
                                    field.key,
                                    field.value.$1,
                                    field.value.$2,
                                    number: field.key == 'manufacture_year',
                                    validate: (value) =>
                                        _validateVehicle(field.key, value),
                                  ),
                              ],
                              2 => _documentStep(),
                              _ => _review(),
                            },
                          ),
                        ),
                      ] else if (!_busy)
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
                if (wizard || _underReview)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _busy ||
                                (_step == 3 &&
                                    !_underReview &&
                                    (!_confirmed || !_reviewReady))
                            ? null
                            : _underReview
                            ? () => Navigator.pop(context)
                            : _step == 3
                            ? _submit
                            : _next,
                        child: Text(
                          _underReview
                              ? 'Done'
                              : _step == 3
                              ? 'Submit for Review'
                              : 'Next',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _cardTitle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: HiGoTheme.navy,
);

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: HiGoTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${step + 1} of 4: ${_steps[step]}',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          for (final (index, label) in const [
            'Driver',
            'Vehicle',
            'Documents',
            'Review',
          ].indexed) ...[
            if (index > 0) const SizedBox(width: 3),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= step
                          ? HiGoTheme.primary
                          : HiGoTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: index == step
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: index == step
                          ? HiGoTheme.primary
                          : HiGoTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
