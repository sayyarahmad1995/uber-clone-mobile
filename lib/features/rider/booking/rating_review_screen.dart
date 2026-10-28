import 'package:flutter/material.dart';

import '../../../app/higo_theme.dart';

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({
    super.key,
    required this.driverName,
    required this.vehicle,
    required this.farePkr,
    required this.rideCategoryName,
  });

  final String driverName;
  final String vehicle;
  final int farePkr;
  final String rideCategoryName;

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final _reviewController = TextEditingController();

  int _rating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _returnHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _submitReview() {
    if (_rating == 0) return;

    final review = _reviewController.text.trim();

    // Temporary UI-only feedback.
    // No review data is sent or stored.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          review.isEmpty
              ? '$_rating-star rating preview complete.'
              : '$_rating-star rating and review preview complete.',
        ),
      ),
    );

    _returnHome();
  }

  String get _ratingDescription => switch (_rating) {
    1 => 'Poor',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Very good',
    5 => 'Excellent',
    _ => 'Tap a star to rate',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: [0, 0.3, 0.72, 1],
                  colors: [
                    Color(0xFFF2EAFF),
                    Colors.white,
                    Colors.white,
                    Color(0xFFE9F4FF),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFFF0EDFF),
                              child: Icon(
                                Icons.person_outline,
                                size: 38,
                                color: HiGoTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Rate ${widget.driverName}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: HiGoTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.vehicle} · '
                            '${widget.rideCategoryName}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'How was your ride?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: HiGoTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final value = index + 1;
                              final selected = value <= _rating;

                              return IconButton(
                                onPressed: () {
                                  setState(() {
                                    _rating = value;
                                  });
                                },
                                icon: Icon(
                                  selected
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: selected
                                      ? const Color(0xFFF0AA2B)
                                      : HiGoTheme.border,
                                  size: 39,
                                ),
                                tooltip: '$value stars',
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ratingDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: HiGoTheme.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 38),
                          const Text(
                            'Write a review (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: HiGoTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _reviewController,
                            minLines: 3,
                            maxLines: 5,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Tell us about your experience...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your feedback helps improve '
                            'the HiGO experience.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: HiGoTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _rating == 0 ? null : _submitReview,
                    child: const Text('Submit Review'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _returnHome,
                    child: const Text('Skip for Now'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Demo only · No feedback submitted',
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
        ],
      ),
    );
  }
}
