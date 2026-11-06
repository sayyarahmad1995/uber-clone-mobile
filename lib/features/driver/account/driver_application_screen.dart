import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../auth/auth_session.dart';
import 'driver_document_picker.dart';

class DriverApplicationScreen extends StatefulWidget {
  const DriverApplicationScreen({super.key, this.session, this.pickDocument});

  final AuthSession? session;
  final Future<Uint8List?> Function(int maxBytes)? pickDocument;

  @override
  State<DriverApplicationScreen> createState() =>
      _DriverApplicationScreenState();
}

const _vehicleFields = {
  'make': 'Vehicle Make',
  'model': 'Vehicle Model',
  'manufacture_year': 'Manufacturing Year',
  'color': 'Vehicle Color',
  'registration_number': 'Registration Number',
};

const _documentLabels = {
  'cnic_front': 'CNIC front',
  'cnic_back': 'CNIC back',
  'registration_image': 'Vehicle registration',
  'insurance_image': 'Vehicle insurance',
};

class _DriverApplicationScreenState extends State<DriverApplicationScreen> {
  AuthSession get _session => widget.session ?? authSession;
  late final Object? _owner = _session.user?['id'];
  var _form = GlobalKey<FormState>();
  final _draft = <String, String>{};
  final _documents = <String, Uint8List>{};
  Map<String, dynamic>? _application;
  String? _error;
  bool _busy = false;
  bool _stale = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _session.addListener(_accountChanged);
    _load();
  }

  bool get _sameAccount => _owner != null && _session.user?['id'] == _owner;

  void _accountChanged() {
    if (_sameAccount) return;
    setState(() {
      _documents.clear();
      _draft.clear();
      _application = null;
    });
  }

  @override
  void dispose() {
    _session.removeListener(_accountChanged);
    _documents.clear();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_sameAccount) return;
    setState(() {
      _busy = true;
      _error = null;
      _stale = false;
    });
    try {
      await action();
    } catch (error) {
      if (mounted && _sameAccount) {
        _stale = error is AuthError && error.code == 'onboarding_conflict';
        _error = _stale
            ? 'The saved application changed. Refresh to load the latest draft.'
            : authErrorMessage(error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _run(() async {
    final application = await _session.driverApplication(accountId: _owner);
    if (!mounted || !_sameAccount) return;
    if (!_adoptDraft(application['draft'])) _draft.clear();
    _documents.clear();
    _form = GlobalKey<FormState>();
    _draft.putIfAbsent(
      'legal_name',
      () => _session.user?['name'] as String? ?? '',
    );
    _application = application;
    _step = (int.tryParse(_draft['step'] ?? '') ?? 0).clamp(0, 3);
    if (_step == 3 && !_readyToSubmit) _step = 2;
    if (_step >= 2 &&
        _vehicleFields.keys.any((key) => (_draft[key] ?? '').isEmpty)) {
      _step = 1;
    }
    if ((_draft['legal_name'] ?? '').isEmpty) _step = 0;
  });

  bool _adoptDraft(Object? value) {
    if (value is! Map) return false;
    _draft
      ..clear()
      ..addAll(value.cast<String, String>());
    return true;
  }

  Future<void> _persist(Map<String, String> values) async {
    final response = await _session.saveDriverApplicationDraft(
      values,
      accountId: _owner,
    );
    if (!mounted || !_sameAccount) return;
    _application = response;
    if (!_adoptDraft(response['draft'])) {
      _draft
        ..clear()
        ..addAll(values);
    }
  }

  Future<void> _advanceDetails() => _run(() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    await _persist({..._draft, 'step': '${_step + 1}'});
    if (mounted && _sameAccount) _step++;
  });

  bool get _hasIdentity => _draft['identity_saved'] == 'true';
  bool get _hasVehicle => _draft['vehicle_saved'] == 'true';
  bool get _readyToSubmit => _hasIdentity && _hasVehicle;

  Future<void> _choose(String key) => _run(() async {
    final max = key.startsWith('cnic_')
        ? identityDocumentMaxBytes
        : vehicleDocumentMaxBytes;
    final selected = await (widget.pickDocument ?? pickDriverDocument)(max);
    if (selected == null || !mounted || !_sameAccount) return;
    final prepared = await prepareDriverDocument(selected, max);
    if (mounted && _sameAccount) _documents[key] = prepared;
  });

  bool _selectedPair(String first, String second) =>
      _documents.containsKey(first) && _documents.containsKey(second);

  Future<void> _saveDocuments({
    required bool identity,
    required String first,
    required String second,
  }) => _run(() async {
    final result = await _session.saveDriverApplicationDocuments(
      {
        'draft_revision': _draft['revision']!,
        first: base64Encode(_documents[first]!),
        second: base64Encode(_documents[second]!),
      },
      accountId: _owner,
      identity: identity,
    );
    if (!mounted || !_sameAccount) return;
    _application = result;
    _adoptDraft(result['draft']);
    _documents.remove(first);
    _documents.remove(second);
  });

  Future<void> _review() => _run(() async {
    await _persist({..._draft, 'step': '3'});
    if (mounted && _sameAccount) _step = 3;
  });

  Future<void> _submit() => _run(() async {
    final result = await _session.submitDriverApplication(
      accountId: _owner,
      draftRevision: _draft['revision']!,
    );
    if (!mounted || !_sameAccount) return;
    _application = result;
    _adoptDraft(result['draft']);
  });

  Future<void> _back() => _run(() async {
    await _persist({..._draft, 'step': '${_step - 1}'});
    if (mounted && _sameAccount) _step--;
  });

  Widget _field(String key, String label) {
    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: _draft[key],
        enabled: !_busy,
        keyboardType: key == 'manufacture_year' ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label),
        validator: (raw) {
          final value = raw?.trim() ?? '';
          if (value.isEmpty) return 'Enter ${label.toLowerCase()}.';
          if (key == 'legal_name' && utf8.encode(value).length > 150) {
            return 'Use a legal name of up to 150 UTF-8 bytes.';
          }
          if (const {'make', 'model', 'color'}.contains(key) &&
              utf8.encode(value).length > 80) {
            return 'Use up to 80 UTF-8 bytes.';
          }
          if (key == 'registration_number' &&
              !RegExp(
                r'^[A-Z0-9][A-Z0-9 -]{1,23}$',
              ).hasMatch(value.toUpperCase())) {
            return 'Enter 2 to 24 letters, numbers, spaces or hyphens.';
          }
          if (key == 'manufacture_year') {
            final year = int.tryParse(value);
            if (year == null || year < 1900 || year > DateTime.now().year + 1) {
              return 'Enter a valid manufacturing year.';
            }
          }
          return null;
        },
        onSaved: (raw) => _draft[key] = raw!.trim(),
      ),
    );
  }

  List<Widget> _documentGroup({
    required bool identity,
    required bool saved,
    required String first,
    required String second,
    required String title,
  }) => [
    Text(title, style: Theme.of(context).textTheme.titleMedium),
    if (saved)
      const ListTile(
        leading: Icon(Icons.check_circle_outline),
        title: Text('Both images saved'),
        contentPadding: EdgeInsets.zero,
      ),
    for (final key in [first, second])
      OutlinedButton(
        onPressed: _busy ? null : () => _choose(key),
        child: Text(
          '${saved || _documents.containsKey(key) ? 'Replace' : 'Choose'} ${_documentLabels[key]}',
        ),
      ),
    if (!saved ||
        _documents.containsKey(first) ||
        _documents.containsKey(second))
      FilledButton(
        onPressed: _busy || !_selectedPair(first, second)
            ? null
            : () => _saveDocuments(
                identity: identity,
                first: first,
                second: second,
              ),
        child: Text(identity ? 'Save CNIC images' : 'Save vehicle images'),
      ),
  ];

  List<Widget> _stepContent() => switch (_step) {
    0 || 1 => [
      Form(
        key: _form,
        child: Column(
          children: [
            if (_step == 0)
              _field('legal_name', 'Legal name')
            else
              for (final field in _vehicleFields.entries)
                _field(field.key, field.value),
          ],
        ),
      ),
      FilledButton(
        onPressed: _busy ? null : _advanceDetails,
        child: const Text('Save and continue'),
      ),
    ],
    2 => [
      const Text(
        'Choose clear JPEG or PNG images. Each CNIC side can be up to 1 MB. '
        'Each vehicle document can be up to 2 MB.',
      ),
      const SizedBox(height: 16),
      ..._documentGroup(
        identity: true,
        saved: _hasIdentity,
        first: 'cnic_front',
        second: 'cnic_back',
        title: 'Identity documents',
      ),
      const SizedBox(height: 16),
      ..._documentGroup(
        identity: false,
        saved: _hasVehicle,
        first: 'registration_image',
        second: 'insurance_image',
        title: 'Vehicle documents',
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy || !_readyToSubmit || _documents.isNotEmpty
            ? null
            : _review,
        child: const Text('Continue to review'),
      ),
    ],
    _ => [
      Text('Driver: ${_draft['legal_name']}'),
      Text('Vehicle: ${_draft['make']} ${_draft['model']}'),
      Text('Manufacturing year: ${_draft['manufacture_year']}'),
      Text('Color: ${_draft['color']}'),
      Text('Registration: ${_draft['registration_number']}'),
      const Text('All required documents are saved.'),
      FilledButton(
        onPressed: _busy || !_readyToSubmit ? null : _submit,
        child: const Text('Submit for Review'),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pendingReview = _application?['status'] == 'pending_review';
    final title = pendingReview
        ? 'Application Pending Review'
        : const [
            'Driver Details',
            'Vehicle Details',
            'Upload Documents',
            'Review & Submit',
          ][_step];
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: !_sameAccount
            ? const Center(
                child: Text('Sign in to view your driver application.'),
              )
            : SafeArea(
                child: ListView(
                  key: ValueKey(pendingReview ? 'pending_review' : _step),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null) Text(_error!),
                    if (_stale) ...[
                      TextButton(
                        onPressed: _load,
                        child: const Text('Refresh application'),
                      ),
                    ],
                    if (pendingReview) ...[
                      const Text(
                        'Your application has been submitted for review.',
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _load,
                        child: const Text('Refresh status'),
                      ),
                    ] else if (_application != null)
                      ..._stepContent()
                    else if (!_busy)
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    if (!pendingReview && _application != null && _step > 0)
                      TextButton(
                        onPressed: _busy ? null : _back,
                        child: const Text('Previous step'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
