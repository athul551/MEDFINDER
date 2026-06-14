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
      backgroundColor: const Color(0xFFF8FDFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        title: Text(
          'Nearby Pharmacies',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.teal.shade900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = pharmacies[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      expansionTileTheme: ExpansionTileThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.all(20),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.local_pharmacy_outlined,
                          color: Colors.teal.shade700,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        pharmacy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.address,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (pharmacy.reviewCount > 0) ...[
                              const SizedBox(height: 8),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            children: [
                              PharmacyRatingDashboard(
                                pharmacy: pharmacy,
                                compact: true,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _openVisitReview(context, pharmacy),
                                  icon: const Icon(Icons.rate_review_outlined, size: 20),
                                  label: const Text('Rate visit', style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  )),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal.shade700,
                                    side: BorderSide(color: Colors.teal.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
