import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/auth_session.dart';
import 'driver_picker_cleanup_stub.dart'
    if (dart.library.io) 'driver_picker_cleanup.dart';

const _maxImageBytes = 1024 * 1024;

Future<Uint8List?> _pickImage() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      return await const MethodChannel(
        'higo/driver_documents',
      ).invokeMethod<Uint8List>('pickImage');
    } on PlatformException catch (error) {
      throw AuthError(error.message ?? 'Unable to select an image.');
    }
  }
  const images = XTypeGroup(
    label: 'JPEG or PNG',
    extensions: ['jpg', 'jpeg', 'png'],
    mimeTypes: ['image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
  );
  final file = await openFile(acceptedTypeGroups: [images]);
  if (file == null) return null;
  try {
    if (await file.length() > _maxImageBytes) {
      throw const AuthError('Choose an image under 1 MB.');
    }
    return await file.readAsBytes();
  } finally {
    await removeImportedDriverImage(file.path);
  }
}

class DriverIdentityScreen extends StatefulWidget {
  const DriverIdentityScreen({super.key, this.session, this.pickImage});

  final AuthSession? session;
  final Future<Uint8List?> Function()? pickImage;

  @override
  State<DriverIdentityScreen> createState() => _DriverIdentityScreenState();
}

class _DriverIdentityScreenState extends State<DriverIdentityScreen> {
  AuthSession get _session => widget.session ?? authSession;
  late final Object? _accountId = _session.user?['id'];
  late final _name = TextEditingController(
    text: _session.user?['name'] as String? ?? '',
  );
  Uint8List? _front;
  Uint8List? _back;
  Map<String, dynamic>? _submission;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _session.addListener(_accountChanged);
    _load();
  }

  void _accountChanged() {
    if (_session.user?['id'] == _accountId) return;
    setState(() {
      _front = null;
      _back = null;
      _submission = null;
      _name.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.user?['id'] != _accountId) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final submission = await _session.driverIdentitySubmission(
        accountId: _accountId,
      );
      if (!mounted) return;
      _submission = submission;
      if (submission['legal_name'] case final String name) _name.text = name;
    } catch (error) {
      if (mounted) _error = authErrorMessage(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose({required bool front}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await (widget.pickImage ?? _pickImage)();
      if (!mounted || image == null || _session.user?['id'] != _accountId) {
        return;
      }
      if (front) {
        _front = image;
      } else {
        _back = image;
      }
      _error = null;
    } catch (error) {
      if (mounted) _error = authErrorMessage(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final front = _front;
    final back = _back;
    final name = _name.text.trim();
    if (_busy || front == null || back == null) return;
    if (name.isEmpty || utf8.encode(name).length > 150) {
      setState(() => _error = 'Enter a legal name of up to 150 UTF-8 bytes.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final submission = await _session.submitDriverIdentity({
        'legal_name': name,
        'cnic_front': base64Encode(front),
        'cnic_back': base64Encode(back),
      }, accountId: _accountId);
      if (!mounted) return;
      _submission = submission;
      _front = null;
      _back = null;
    } catch (error) {
      if (mounted) _error = authErrorMessage(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_accountChanged);
    _front = null;
    _back = null;
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Driver identity')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        if (_submission == null && !_busy)
          TextButton(onPressed: _load, child: const Text('Retry')),
        if (_submission != null) ...[
          if (_submission?['status'] == 'submitted')
            Text('Identity submitted · Version ${_submission!['version']}'),
          const Text(
            'Enter your legal name and upload both sides of your CNIC. Use a JPEG or PNG of up to 1 MB per side.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Legal name'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : () => _choose(front: true),
            child: Text(
              _front == null ? 'Choose CNIC front' : 'Replace CNIC front',
            ),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => _choose(front: false),
            child: Text(
              _back == null ? 'Choose CNIC back' : 'Replace CNIC back',
            ),
          ),
          FilledButton(
            onPressed: _busy || _front == null || _back == null
                ? null
                : _submit,
            child: const Text('Submit identity'),
          ),
        ],
      ],
    ),
  );
}
