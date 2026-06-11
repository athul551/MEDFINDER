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

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

  Future<void> _openVisitReview(BuildContext context, Pharmacy pharmacy) async {
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) {
      showAppSnackBar(context, 'Please sign in to leave a review.', isError: true);
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
      appBar: AppBar(title: const Text('Nearby pharmacies')),
      body: StreamBuilder<List<Pharmacy>>(
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = pharmacies[index];
              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.local_pharmacy_outlined),
                  title: Text(pharmacy.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.address),
                      if (pharmacy.reviewCount > 0) ...[
                        const SizedBox(height: 4),
                        StarRatingDisplay(
                          rating: pharmacy.averageRating,
                          size: 16,
                          showValue: true,
                        ),
                      ],
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          PharmacyRatingDashboard(
                            pharmacy: pharmacy,
                            compact: true,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openVisitReview(context, pharmacy),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Rate visit'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
