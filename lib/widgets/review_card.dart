import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pharmacy_review.dart';
import 'star_rating_display.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final PharmacyReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.userName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(review.triggerType.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StarRatingDisplay(rating: review.overallRating.toDouble()),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment),
            ],
            const SizedBox(height: 8),
            Text(
              DateFormat.yMMMd().format(review.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
