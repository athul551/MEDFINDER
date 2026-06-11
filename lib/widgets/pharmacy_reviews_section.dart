import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pharmacy.dart';
import '../services/firestore_service.dart';
import 'empty_state.dart';
import 'pharmacy_rating_dashboard.dart';
import 'review_card.dart';

class PharmacyReviewsSection extends StatelessWidget {
  const PharmacyReviewsSection({
    super.key,
    required this.pharmacy,
    this.compact = false,
  });

  final Pharmacy pharmacy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PharmacyRatingDashboard(pharmacy: pharmacy, compact: compact),
        const SizedBox(height: 16),
        Text(
          'Customer reviews',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        StreamBuilder(
          stream: context
              .read<FirestoreService>()
              .watchReviewsForPharmacy(pharmacy.pharmacyId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load reviews',
                message: snapshot.error.toString(),
              );
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return const EmptyState(
                icon: Icons.rate_review_outlined,
                title: 'No reviews yet',
                message: 'Customer reviews will appear here.',
              );
            }
            return Column(
              children: reviews
                  .map((review) => ReviewCard(review: review))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
