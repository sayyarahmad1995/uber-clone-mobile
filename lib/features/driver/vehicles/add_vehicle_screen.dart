import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../auth/auth_session.dart';
import '../account/driver_document_picker.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key, this.vehicle, this.pickDocument});

  final Map<String, dynamic>? vehicle;
  final Future<Uint8List?> Function()? pickDocument;

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _form = GlobalKey<FormState>();
  Object? _owner;
  late final _make = _controller('make');
  late final _model = _controller('model');
  late final _year = _controller('manufacture_year');
  late final _color = _controller('color');
  late final _registration = _controller('registration_number');
  Uint8List? _registrationImage;
  Uint8List? _insuranceImage;
  bool _busy = false;
  String? _error;

  TextEditingController _controller(String key) =>
      TextEditingController(text: widget.vehicle?[key]?.toString() ?? '');

  @override
  void initState() {
    super.initState();
    // Bind selected documents to the account that opened this draft.
    _owner = authSession.user?['id'];
    authSession.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (authSession.user?['id'] == _owner) return;
    setState(() {
      _registrationImage = null;
      _insuranceImage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && authSession.user?['id'] != _owner) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _choose({required bool registration}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image =
          await (widget.pickDocument ??
              () => pickDriverDocument(vehicleDocumentMaxBytes))();
      if (image == null) return;
      final prepared = await prepareDriverDocument(
        image,
        vehicleDocumentMaxBytes,
      );
      if (!mounted || authSession.user?['id'] != _owner) return;
      if (registration) {
        _registrationImage = prepared;
      } else {
        _insuranceImage = prepared;
      }
    } catch (error) {
      if (mounted) _error = authErrorMessage(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final registration = _registrationImage;
    final insurance = _insuranceImage;
    if (registration == null || insurance == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authSession.submitVehicle({
        if (widget.vehicle != null)
          'vehicle_id': widget.vehicle!['vehicle_id'].toString(),
        'make': _make.text.trim(),
        'model': _model.text.trim(),
        'manufacture_year': _year.text.trim(),
        'color': _color.text.trim(),
        'registration_number': _registration.text.trim(),
        'registration_image': base64Encode(registration),
        'insurance_image': base64Encode(insurance),
      }, accountId: _owner);
      if (mounted && ModalRoute.isCurrentOf(context) == true) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) _error = authErrorMessage(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    authSession.removeListener(_accountChanged);
    _registrationImage = null;
    _insuranceImage = null;
    for (final field in [_make, _model, _year, _color, _registration]) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool year = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: year ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Enter ${label.toLowerCase()}.';
        if (year) {
          final number = int.tryParse(text);
          if (number == null ||
              number < 1900 ||
              number > DateTime.now().year + 1) {
            return 'Enter a valid manufacturing year.';
          }
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(_make, 'Vehicle Make'),
            _field(_model, 'Vehicle Model'),
            _field(_year, 'Manufacturing Year', year: true),
            _field(_color, 'Vehicle Color'),
            _field(_registration, 'Registration Number'),
            const Text(
              'Attach the registration and insurance documents as JPEG or PNG images of up to 2 MB each.',
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _choose(registration: true),
              child: Text(
                _registrationImage == null
                    ? 'Choose registration document'
                    : 'Replace registration document',
              ),
            ),
            OutlinedButton(
              onPressed: _busy ? null : () => _choose(registration: false),
              child: Text(
                _insuranceImage == null
                    ? 'Choose insurance document'
                    : 'Replace insurance document',
              ),
            ),
            if (_error != null) Text(_error!),
            if (_busy) const LinearProgressIndicator(),
            FilledButton(
              onPressed:
                  _busy || _registrationImage == null || _insuranceImage == null
                  ? null
                  : _submit,
              child: const Text('Submit vehicle'),
            ),
          ],
        ),
      ),
    ),
  );
}
