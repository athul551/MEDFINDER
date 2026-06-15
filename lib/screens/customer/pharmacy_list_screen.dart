import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/pharmacy_rating_dashboard.dart';
import '../../widgets/star_rating_display.dart';
import 'write_review_screen.dart';
import '../../utils/app_constants.dart';
import '../../providers/app_auth_provider.dart';
import '../../utils/snackbars.dart';
import 'customer_ui.dart';

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  Future<void> _openVisitReview(BuildContext context, Pharmacy pharmacy) async {
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) {
      showAppSnackBar(context, 'Please sign in to leave a review.',
          isError: true);
      return;
    }

    final firestore = context.read<FirestoreService>();
    final canReview = await firestore.canReviewPharmacy(
      userId: user.uid,
      pharmacyId: pharmacy.pharmacyId,
      triggerType: ReviewTrigger.visit,
    );
    if (!context.mounted) return;

    if (!canReview) {
      showAppSnackBar(
        context,
        'Visit this pharmacy first to leave a review.',
        isError: true,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          pharmacy: pharmacy,
          triggerType: ReviewTrigger.visit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Nearby pharmacies',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: StreamBuilder<List<Pharmacy>>(
          stream: context.read<FirestoreService>().watchVerifiedPharmacies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading pharmacies...');
            }
            final pharmacies = snapshot.data ?? [];
            if (pharmacies.isEmpty) {
              return const EmptyState(
                icon: Icons.store_mall_directory_outlined,
                title: 'No pharmacies',
                message: 'Pharmacy accounts will appear here.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomerHeroCard(
                  title: 'Choose your pharmacy',
                  subtitle:
                      '${pharmacies.length} verified pharmacies are ready for reviews and pickup planning.',
                  icon: Icons.storefront_rounded,
                  badges: const [
                    CustomerPill(
                      icon: Icons.star_border_rounded,
                      label: 'Ratings',
                    ),
                    CustomerPill(
                      icon: Icons.rate_review_outlined,
                      label: 'Visit reviews',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...pharmacies.asMap().entries.map(
                  (e) => AnimatedStaggerItem(
                    delay: e.key * 60,
                    child: _PharmacyListCard(
                      pharmacy: e.value,
                      onRateVisit: () => _openVisitReview(context, e.value),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PharmacyListCard extends StatelessWidget {
  const _PharmacyListCard({
    required this.pharmacy,
    required this.onRateVisit,
  });

  final Pharmacy pharmacy;
  final VoidCallback onRateVisit;

  @override
  Widget build(BuildContext context) {
    return CustomerSurfaceCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 14),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: CustomerIconBadge(
            icon: Icons.local_pharmacy_outlined,
            color: Colors.teal.shade700,
          ),
          title: Text(
            pharmacy.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pharmacy.address),
                if (pharmacy.reviewCount > 0) ...[
                  const SizedBox(height: 6),
                  StarRatingDisplay(
                    rating: pharmacy.averageRating,
                    size: 16,
                    showValue: true,
                  ),
                ],
              ],
            ),
          ),
          children: [
            PharmacyRatingDashboard(
              pharmacy: pharmacy,
              compact: true,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onRateVisit,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Rate visit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
