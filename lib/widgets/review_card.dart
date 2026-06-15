import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pharmacy_review.dart';
import 'star_rating_display.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final PharmacyReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.94 * 255).round()),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha((0.82 * 255).round()),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade900.withAlpha((0.07 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.userName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha((0.10 * 255).round()),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    review.triggerType.label,
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StarRatingDisplay(rating: review.overallRating.toDouble()),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.comment,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  DateFormat.yMMMd().format(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
