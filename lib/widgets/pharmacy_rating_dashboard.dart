import 'package:flutter/material.dart';

import '../models/pharmacy.dart';
import '../models/pharmacy_review.dart';
import 'star_rating_display.dart';

class PharmacyRatingDashboard extends StatelessWidget {
  const PharmacyRatingDashboard({
    super.key,
    required this.pharmacy,
    this.compact = false,
  });

  final Pharmacy pharmacy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final summary = PharmacyRatingSummary.fromPharmacy(pharmacy);
    final theme = Theme.of(context);

    if (summary.reviewCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.star_outline, color: Colors.grey.shade500, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No reviews yet. Be the first to rate this pharmacy.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pharmacy.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StarRatingDisplay(
                  rating: summary.averageRating,
                  size: compact ? 22 : 28,
                  showValue: true,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Based on ${summary.reviewCount} '
              '${summary.reviewCount == 1 ? 'Review' : 'Reviews'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _CategoryRow(
              label: 'Availability',
              value: summary.availabilityAvg,
            ),
            _CategoryRow(
              label: 'Pricing',
              value: summary.pricingAvg,
            ),
            _CategoryRow(
              label: 'Service',
              value: summary.serviceAvg,
            ),
            _CategoryRow(
              label: 'Delivery',
              value: summary.deliveryAvg,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value / 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
