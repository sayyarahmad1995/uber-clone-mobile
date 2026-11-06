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
  bool _editing = false;
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
        _stale = error is AuthError && error.status == 409;
        _error = _stale
            ? 'The saved application changed. Refresh or replace the saved documents.'
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
    _editing =
        application['status'] == 'draft' ||
        (application['status'] != 'under_review' && _draft['step'] != null);
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

  bool _hasPositiveNumber(String key) =>
      (int.tryParse(_draft[key] ?? '') ?? 0) > 0;

  bool get _hasIdentity => _hasPositiveNumber('identity_version');
  bool get _hasVehicle =>
      _hasPositiveNumber('vehicle_version') && _hasPositiveNumber('vehicle_id');
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

  bool get _canUpload =>
      (_hasIdentity ||
          (_documents.containsKey('cnic_front') &&
              _documents.containsKey('cnic_back'))) &&
      (_hasVehicle ||
          (_documents.containsKey('registration_image') &&
              _documents.containsKey('insurance_image')));

  Future<void> _upload() => _run(() async {
    if (!_hasIdentity) {
      final saved = await _session.submitDriverIdentity({
        if (_draft['revision'] case final String revision)
          'draft_revision': revision,
        'legal_name': _draft['legal_name']!,
        'cnic_front': base64Encode(_documents['cnic_front']!),
        'cnic_back': base64Encode(_documents['cnic_back']!),
      }, accountId: _owner);
      if (!mounted || !_sameAccount) return;
      if (!_adoptDraft(saved['application_draft'])) {
        _draft['identity_version'] = saved['version'].toString();
        if (saved['legal_name'] case final String name) {
          _draft['legal_name'] = name;
        }
      }
      _documents.remove('cnic_front');
      _documents.remove('cnic_back');
    }
    // Older API responses require a separate save. Revision-aware uploads
    // attach the version to the draft in the same transaction as the upload.
    if (!_draft.containsKey('revision')) {
      await _persist({..._draft, 'step': '2'});
    }
    if (!mounted || !_sameAccount) return;
    if (!_hasVehicle) {
      final saved = await _session.submitVehicle({
        if (_draft['revision'] case final String revision)
          'draft_revision': revision,
        if (_hasPositiveNumber('vehicle_id'))
          'vehicle_id': _draft['vehicle_id']!,
        for (final key in _vehicleFields.keys) key: _draft[key]!,
        'registration_image': base64Encode(_documents['registration_image']!),
        'insurance_image': base64Encode(_documents['insurance_image']!),
      }, accountId: _owner);
      if (!mounted || !_sameAccount) return;
      if (!_adoptDraft(saved['application_draft'])) {
        _draft['vehicle_id'] = saved['vehicle_id'].toString();
        _draft['vehicle_version'] = saved['version'].toString();
        for (final key in _vehicleFields.keys) {
          if (saved[key] != null) _draft[key] = saved[key].toString();
        }
      }
      _documents.clear();
    }
    if (_draft['step'] != '3') await _persist({..._draft, 'step': '3'});
    if (mounted && _sameAccount) _step = 3;
  });

  Future<void> _submit() => _run(() async {
    final result = await _session.submitDriverApplication(
      accountId: _owner,
      identityVersion: int.parse(_draft['identity_version']!),
      vehicleId: _draft['vehicle_id']!,
      vehicleVersion: int.parse(_draft['vehicle_version']!),
      draftRevision: _draft['revision'],
    );
    if (!mounted || !_sameAccount) return;
    _application = result;
    _editing = false;
  });

  Future<void> _revise() => _run(() async {
    await _persist({
      ..._draft,
      'identity_version': '',
      'vehicle_version': '',
      'step': '0',
    });
    if (!mounted || !_sameAccount) return;
    _step = 0;
    _editing = true;
  });

  Future<void> _replaceDocuments(String versionKey) => _run(() async {
    final updated = {..._draft}..remove(versionKey);
    await _persist(updated);
    if (mounted && _sameAccount) _draft.remove(versionKey);
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
        onSaved: (raw) {
          final value = raw!.trim();
          if (value != _draft[key]) {
            final keyToClear = key == 'legal_name'
                ? 'identity_version'
                : 'vehicle_version';
            _draft.remove(keyToClear);
          }
          _draft[key] = value;
        },
      ),
    );
  }

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
      for (final doc in _documentLabels.entries)
        if (doc.key.startsWith('cnic_') ? !_hasIdentity : !_hasVehicle)
          OutlinedButton(
            onPressed: _busy ? null : () => _choose(doc.key),
            child: Text(
              '${_documents.containsKey(doc.key) ? 'Replace' : 'Choose'} ${doc.value}',
            ),
          )
        else
          ListTile(
            leading: const Icon(Icons.check),
            title: Text(doc.value),
            subtitle: const Text('Saved'),
          ),
      if (_hasIdentity)
        TextButton(
          onPressed: _busy ? null : () => _replaceDocuments('identity_version'),
          child: const Text('Replace saved CNIC images'),
        ),
      if (_hasVehicle)
        TextButton(
          onPressed: _busy ? null : () => _replaceDocuments('vehicle_version'),
          child: const Text('Replace saved vehicle images'),
        ),
      FilledButton(
        onPressed: _busy || !_canUpload ? null : _upload,
        child: const Text('Save documents and continue'),
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
        child: const Text('Submit application'),
      ),
    ],
  };

  List<Widget> _statusContent() {
    final status = _application?['status'];
    return [
      Text(switch (status) {
        'under_review' => 'Your application has been submitted for review.',
        'approved' => 'Your driver application was approved.',
        'rejected' => 'Update your application before submitting it again.',
        _ => 'Start your application when you are ready.',
      }),
      if (_application?['reason'] case final String reason)
        if (reason.isNotEmpty) Text('Reason: $reason'),
      if (status == 'approved' || status == 'rejected')
        FilledButton(
          onPressed: _busy ? null : _revise,
          child: const Text('Revise application'),
        ),
      OutlinedButton(
        onPressed: _busy ? null : _load,
        child: const Text('Refresh status'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing
        ? const [
            'Driver Details',
            'Vehicle Details',
            'Upload Documents',
            'Review & Submit',
          ][_step]
        : switch (_application?['status']) {
            'under_review' => 'Application Under Review',
            'approved' => 'Application Approved',
            'rejected' => 'Application Needs Changes',
            _ => 'Driver Application',
          };
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null) Text(_error!),
                    if (_stale) ...[
                      TextButton(
                        onPressed: _load,
                        child: const Text('Refresh application'),
                      ),
                      TextButton(
                        onPressed: _revise,
                        child: const Text('Replace saved documents'),
                      ),
                    ],
                    if (_application != null)
                      ...(_editing ? _stepContent() : _statusContent())
                    else if (!_busy)
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    if (_editing && _step > 0)
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
