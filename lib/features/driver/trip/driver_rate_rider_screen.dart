import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';
import '../models/mock_ride_request.dart';

class DriverRateRiderScreen extends StatefulWidget {
  const DriverRateRiderScreen({
    super.key,
    required this.request,
    required this.farePkr,
  });

  final MockRideRequest request;
  final int farePkr;

  @override
  State<DriverRateRiderScreen> createState() => _DriverRateRiderScreenState();
}

class _DriverRateRiderScreenState extends State<DriverRateRiderScreen> {
  static const _feedbackOptions = [
    'Friendly rider',
    'On time',
    'Easy pickup',
    'Respectful',
  ];

  final _reviewController = TextEditingController();
  final Set<String> _selectedTags = {};
  int _rating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _finish({required bool saveRating}) {
    if (saveRating && _rating > 0) {
      final parts = <String>[
        ..._selectedTags,
        if (_reviewController.text.trim().isNotEmpty)
          _reviewController.text.trim(),
      ];

      DriverDemoStore.instance.rateDemoRider(
        requestId: widget.request.id,
        rating: _rating,
        feedback: parts.isEmpty ? null : parts.join(' · '),
      );
    }

    // The first route is our DriverShell.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Rate Rider', style: TextStyle(fontSize: 18)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFFEFECFF),
                          child: Icon(
                            Icons.person,
                            size: 39,
                            color: HiGoTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'How was ${widget.request.riderName}?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rate your experience with the rider.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: HiGoTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final star = index + 1;

                            return IconButton(
                              onPressed: () {
                                setState(() {
                                  _rating = star;
                                });
                              },
                              icon: Icon(
                                star <= _rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFFFB52E),
                                size: 36,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Quick feedback (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in _feedbackOptions)
                              FilterChip(
                                label: Text(tag),
                                selected: _selectedTags.contains(tag),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFFEFECFF),
                                checkmarkColor: HiGoTheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Additional feedback (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HiGoTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reviewController,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Tell us about the trip...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _rating == 0
                        ? null
                        : () => _finish(saveRating: true),
                    child: const Text('Submit Rating'),
                  ),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: () => _finish(saveRating: false),
                  child: const Text('Skip for Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
