import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';

class SubmitBidScreen extends StatefulWidget {
  const SubmitBidScreen({
    super.key,
    required this.request,
    this.existingBidPkr,
  });

  final MockRideRequest request;
  final int? existingBidPkr;

  @override
  State<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends State<SubmitBidScreen> {
  late final TextEditingController _fareController;

  @override
  void initState() {
    super.initState();
    _fareController = TextEditingController(
      text:
          widget.existingBidPkr?.toString() ??
          widget.request.estimatedFarePkr.toString(),
    );
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  void _changeFare(int delta) {
    final current = int.tryParse(_fareController.text.trim()) ?? 0;

    final next = current + delta;
    _fareController.text = (next < 1 ? 1 : next).toString();
  }

  void _submit() {
    final value = int.tryParse(_fareController.text.trim());

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid fare.')));
      return;
    }

    DriverDemoStore.instance.submitBid(widget.request.id, value);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_map.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.76,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 22,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: HiGoTheme.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Trip details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'City Ride · ${request.category}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: HiGoTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Detail(
                        icon: Icons.radio_button_checked,
                        label: 'Pickup',
                        value: request.pickup,
                      ),
                      const SizedBox(height: 14),
                      _Detail(
                        icon: Icons.location_on,
                        label: 'Destination',
                        value: request.destination,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: HiGoTheme.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text('${request.durationMinutes} min'),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.route,
                            size: 18,
                            color: HiGoTheme.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text('${request.distanceKm} km'),
                        ],
                      ),
                      const Divider(height: 30),
                      const Text(
                        'Reference estimate',
                        style: TextStyle(
                          fontSize: 12,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${request.estimatedFarePkr}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your bid (PKR)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: HiGoTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: () => _changeFare(-50),
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _fareController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Fare',
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.outlined(
                            onPressed: () => _changeFare(50),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(
                          widget.existingBidPkr == null
                              ? 'Submit Bid'
                              : 'Update Demo Bid',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mock fare only · No bid sent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: HiGoTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: HiGoTheme.primary, size: 21),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HiGoTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
