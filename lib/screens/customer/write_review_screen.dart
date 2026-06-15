import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/pharmacy_review.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/snackbars.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/star_rating_display.dart';
import 'customer_ui.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.pharmacy,
    required this.triggerType,
    this.reservationId,
  });

  final Pharmacy pharmacy;
  final ReviewTrigger triggerType;
  final String? reservationId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _availability = 5;
  int _pricing = 5;
  int _service = 5;
  int _delivery = 5;
  bool _isSaving = false;

  int get _overallRating => PharmacyReview.computeOverallRating(
        availabilityRating: _availability,
        pricingRating: _pricing,
        serviceRating: _service,
        deliveryRating: _delivery,
      );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final review = PharmacyReview(
        reviewId: '',
        pharmacyId: widget.pharmacy.pharmacyId,
        pharmacyName: widget.pharmacy.name,
        userId: user.uid,
        userName: user.name,
        triggerType: widget.triggerType,
        reservationId: widget.reservationId,
        overallRating: _overallRating,
        availabilityRating: _availability,
        pricingRating: _pricing,
        serviceRating: _service,
        deliveryRating: _delivery,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await context.read<FirestoreService>().createReview(review);
      if (mounted) {
        showAppSnackBar(context, 'Thank you for your review!');
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Rate ${widget.pharmacy.name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomerSurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Overall rating',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.teal.shade900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  StarRatingDisplay(
                    rating: _overallRating.toDouble(),
                    size: 28,
                    showValue: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ReviewRatingLabels.forRating(_overallRating),
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CategoryRatingTile(
              label: 'Availability',
              rating: _availability,
              onChanged: (value) => setState(() => _availability = value),
            ),
            _CategoryRatingTile(
              label: 'Pricing',
              rating: _pricing,
              onChanged: (value) => setState(() => _pricing = value),
            ),
            _CategoryRatingTile(
              label: 'Service',
              rating: _service,
              onChanged: (value) => setState(() => _service = value),
            ),
            _CategoryRatingTile(
              label: 'Delivery',
              rating: _delivery,
              onChanged: (value) => setState(() => _delivery = value),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _commentController,
              label: 'Your review (optional)',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Submit review',
              icon: Icons.rate_review_outlined,
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRatingTile extends StatelessWidget {
  const _CategoryRatingTile({
    required this.label,
    required this.rating,
    required this.onChanged,
  });

  final String label;
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomerSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade800,
                    ),
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: () => onChanged(value),
                  icon: Icon(
                    value <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber.shade700,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
