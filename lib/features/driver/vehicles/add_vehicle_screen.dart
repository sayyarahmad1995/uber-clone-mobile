import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';
import '../models/vehicle_service_catalog.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _registration = TextEditingController();
  bool _allowExit = false;

  final VehicleServiceCatalog _catalog = const MockVehicleServiceCatalog();

  List<VehicleService> _services = [];
  VehicleService? _selectedService;
  VehicleServiceCategory? _selectedCategory;

  bool _loadingServices = true;
  String? _servicesError;

  int _step = 0;

  List<String> get _steps => [
    'Service',
    if (_selectedService?.hasCategories == true) 'Category',
    'Vehicle Info',
    'Documents',
    'Review',
  ];

  String get _currentStep => _steps[_step];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _catalog.loadServices();
      if (!mounted) return;

      setState(() {
        _services = services;
        _loadingServices = false;
        _servicesError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingServices = false;
        _servicesError = 'Unable to load services.';
      });
    }
  }

  bool _submitted = false;

  final Map<String, bool> _documents = {
    'CNIC Front': false,
    'CNIC Back': false,
    'Vehicle Registration': false,
    'Vehicle Insurance': false,
  };

  bool get _documentsReady => _documents.values.every((value) => value);

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _registration.dispose();
    super.dispose();
  }

  void _next() {
    switch (_currentStep) {
      case 'Service':
        if (_selectedService == null) {
          _message('Select a service to continue.');
          return;
        }
        break;

      case 'Category':
        if (_selectedCategory == null) {
          _message('Select a category to continue.');
          return;
        }
        break;

      case 'Vehicle Info':
        if (!_formKey.currentState!.validate()) {
          return;
        }
        break;

      case 'Documents':
        if (!_documentsReady) {
          _message('Complete all demo document checks first.');
          return;
        }
        break;

      case 'Review':
        return;
    }

    if (_step < _steps.length - 1) {
      setState(() => _step++);
    }
  }

  Future<void> _back() async {
    if (_submitted) {
      Navigator.of(context).pop();
      return;
    }
    if (_step > 0) {
      setState(() => _step--);
      return;
    }

    final navigator = Navigator.of(context);
    final shouldExit = await _confirmExit();
    if (!mounted || !navigator.mounted || !shouldExit) return;
    setState(() => _allowExit = true);
    navigator.pop();
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (_submitted) return;
    final service = _selectedService;
    if (service == null ||
        (service.hasCategories && _selectedCategory == null)) {
      _message('Complete service and category selection.');
      return;
    }

    try {
      DriverDemoStore.instance.registerDemoVehicle(
        make: _make.text,
        model: _model.text,
        registrationNumber: _registration.text,
        serviceId: service.id,
        categoryId: _selectedCategory?.id,
        category: _selectedCategory?.name ?? service.name,
      );
      setState(() => _submitted = true);
    } on StateError catch (error) {
      _message(error.message);
    } on ArgumentError catch (error) {
      _message(
        error.message?.toString() ?? 'Please check the vehicle information.',
      );
    }
  }

  Future<bool> _confirmExit() async {
    if (_submitted) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard registration?'),
        content: const Text(
          'Your unfinished demo vehicle details will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _submitted || _allowExit,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_step > 0 && !_submitted) {
          setState(() => _step--);
          return;
        }

        final navigator = Navigator.of(context);

        final shouldExit = await _confirmExit();

        if (!mounted || !navigator.mounted || !shouldExit) return;

        setState(() => _allowExit = true);
        navigator.pop();
      },

      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
          title: Text(
            _submitted ? 'Registration Submitted' : 'Add Vehicle',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: HiGoTheme.navy,
            ),
          ),
        ),
        body: Container(
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
              stops: [0, 0.27, 0.74, 1],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (!_submitted) _StepIndicator(current: _step, labels: _steps),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: _submitted
                        ? _successContent()
                        : switch (_currentStep) {
                            'Service' => _serviceSelection(),
                            'Category' => _categorySelection(),
                            'Vehicle Info' => _vehicleInformation(),
                            'Documents' => _documentInformation(),
                            _ => _reviewInformation(),
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitted
                          ? () => Navigator.pop(context)
                          : _currentStep == 'Review'
                          ? _submit
                          : (_currentStep == 'Service' &&
                                (_loadingServices ||
                                    _servicesError != null ||
                                    _services.isEmpty))
                          ? null
                          : _next,
                      child: Text(
                        _submitted
                            ? 'Back to My Vehicles'
                            : _currentStep == 'Review'
                            ? 'Submit Demo Application'
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

  Widget _vehicleInformation() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Vehicle Information',
            subtitle: 'Enter the details of your vehicle.',
          ),
          const SizedBox(height: 18),
          _Field(controller: _make, label: 'Vehicle Make', hint: 'e.g. Toyota'),
          _Field(
            controller: _model,
            label: 'Vehicle Model',
            hint: 'e.g. Corolla',
          ),
          _Field(
            controller: _year,
            label: 'Manufacturing Year',
            hint: 'e.g. 2022',
            number: true,
            validator: (text) {
              final value = int.tryParse(text?.trim() ?? '');
              final currentYear = DateTime.now().year;
              if (value == null || value < 1900 || value > currentYear + 1) {
                return 'Enter a valid manufacturing year.';
              }
              return null;
            },
          ),
          _Field(
            controller: _color,
            label: 'Vehicle Color',
            hint: 'e.g. White',
          ),
          _Field(
            controller: _registration,
            label: 'Registration Number',
            hint: 'e.g. ABC-123',
          ),
          const Text(
            'Fields and category choices are provisional UI examples. '
            'Final registration requirements will follow the Go API.',
            style: TextStyle(fontSize: 11, color: HiGoTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _documentInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Upload Documents',
          subtitle: 'Simulate attaching documents to this vehicle.',
        ),
        const SizedBox(height: 14),
        const Text(
          'Demo only: tapping a document marks a sample attachment '
          'as provided. No file is selected, stored, or uploaded.',
          style: TextStyle(
            fontSize: 12,
            color: HiGoTheme.secondaryText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        for (final name in _documents.keys) ...[
          _DocumentCard(
            title: name,
            attached: _documents[name]!,
            onTap: () => setState(() {
              _documents[name] = !_documents[name]!;
            }),
          ),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  Widget _reviewInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Review & Submit',
          subtitle: 'Confirm your demo vehicle application.',
        ),
        const SizedBox(height: 17),
        _ReviewCard(
          title: 'Vehicle Details',
          children: [
            _ReviewRow('Service', _selectedService?.name ?? 'Not selected'),
            if (_selectedCategory != null)
              _ReviewRow('Category', _selectedCategory!.name),
            _ReviewRow('Make', _make.text.trim()),
            _ReviewRow('Model', _model.text.trim()),
            _ReviewRow('Year', _year.text.trim()),
            _ReviewRow('Color', _color.text.trim()),
            _ReviewRow('Registration', _registration.text.trim().toUpperCase()),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: 'Demo Documents',
          children: [
            for (final name in _documents.keys)
              _ReviewRow(
                name,
                _documents[name]! ? 'Sample attached' : 'Missing',
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Submitting will add this vehicle to your local '
          'My Vehicles list with Pending status. '
          'No API request or approval action takes place.',
          style: TextStyle(
            fontSize: 12,
            color: HiGoTheme.secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _successContent() {
    return Column(
      children: [
        const SizedBox(height: 60),
        const CircleAvatar(
          radius: 43,
          backgroundColor: Color(0xFFE9F8EF),
          child: Icon(Icons.check_circle, size: 53, color: Color(0xFF15803D)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Demo Application Submitted!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your sample vehicle has been added locally '
          'with Pending status.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: HiGoTheme.secondaryText),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HiGoTheme.border),
          ),
          child: Column(
            children: [
              Text(
                '${_make.text.trim()} ${_model.text.trim()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: HiGoTheme.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _registration.text.trim().toUpperCase(),
                style: const TextStyle(color: HiGoTheme.secondaryText),
              ),
              const SizedBox(height: 9),
              const Chip(label: Text('Pending · Demo')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No real registration was submitted. '
          'Approval is not simulated automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HiGoTheme.secondaryText),
        ),
      ],
    );
  }

  Widget _serviceSelection() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_servicesError != null) {
      return Column(
        children: [
          Text(_servicesError!),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _loadingServices = true;
                _servicesError = null;
              });
              _loadServices();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_services.isEmpty) {
      return const Center(child: Text('No services available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Select Service',
          subtitle: 'Choose the service for this vehicle.',
        ),
        const SizedBox(height: 18),
        for (final service in _services) ...[
          _SelectionCard(
            title: service.name,
            subtitle: service.description,
            selected: _selectedService?.id == service.id,
            icon: switch (service.id) {
              'city_ride' => Icons.directions_car_outlined,
              'city_to_city' => Icons.route_outlined,
              'courier' => Icons.inventory_2_outlined,
              'delivery' => Icons.local_shipping_outlined,
              'freight' => Icons.fire_truck_outlined,
              _ => Icons.widgets_outlined,
            },
            onTap: () {
              setState(() {
                _selectedService = service;
                _selectedCategory = null;
              });
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _categorySelection() {
    final service = _selectedService;

    if (service == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Select Category',
          subtitle: 'Choose a category for ${service.name}.',
        ),
        const SizedBox(height: 18),
        for (final category in service.categories) ...[
          _SelectionCard(
            title: category.name,
            subtitle: 'Vehicle category',
            icon: Icons.directions_car_outlined,
            selected: _selectedCategory?.id == category.id,
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF5F2FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? HiGoTheme.primary : HiGoTheme.border,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: HiGoTheme.primary, size: 25),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HiGoTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HiGoTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? HiGoTheme.primary : HiGoTheme.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= current
                          ? HiGoTheme.primary
                          : HiGoTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: i == current
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == current
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: HiGoTheme.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: HiGoTheme.secondaryText),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.number = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool number;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required.';
              }
              return null;
            },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.attached,
    required this.onTap,
  });

  final String title;
  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HiGoTheme.border),
          ),
          child: Row(
            children: [
              Icon(
                attached ? Icons.check_circle : Icons.upload_file_outlined,
                color: attached ? const Color(0xFF15803D) : HiGoTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: HiGoTheme.navy,
                  ),
                ),
              ),
              Text(
                attached ? 'Sample attached' : 'Add sample',
                style: TextStyle(
                  fontSize: 11,
                  color: attached ? const Color(0xFF15803D) : HiGoTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HiGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: HiGoTheme.navy,
            ),
          ),
          const Divider(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                fontWeight: FontWeight.w700,
                color: HiGoTheme.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
