import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/pharmacy.dart';
import '../../models/stock_item.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/snackbars.dart';
import '../../widgets/pharmacy_reviews_section.dart';
import '../../widgets/star_rating_display.dart';
import 'create_subscription_screen.dart';
import 'customer_ui.dart';
import 'reservation_screen.dart';
import 'write_review_screen.dart';

class PharmacyDetailsScreen extends StatelessWidget {
  const PharmacyDetailsScreen({
    super.key,
    required this.stock,
    required this.pharmacy,
    this.distanceKm,
  });

  final StockItem stock;
  final Pharmacy pharmacy;
  final double? distanceKm;

  Future<void> _launch(Uri uri, BuildContext context) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Could not open ${uri.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _openVisitReview(BuildContext context, Pharmacy current) async {
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) {
      showAppSnackBar(context, 'Please sign in to leave a review.',
          isError: true);
      return;
    }

    final firestore = context.read<FirestoreService>();
    final canReview = await firestore.canReviewPharmacy(
      userId: user.uid,
      pharmacyId: current.pharmacyId,
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
          pharmacy: current,
          triggerType: ReviewTrigger.visit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(pharmacy.latitude, pharmacy.longitude);
    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          pharmacy.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: StreamBuilder<Pharmacy?>(
          stream: context
              .read<FirestoreService>()
              .watchPharmacyById(pharmacy.pharmacyId),
          builder: (context, snapshot) {
            final currentPharmacy = snapshot.data ?? pharmacy;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomerHeroCard(
                  title: currentPharmacy.name,
                  subtitle: currentPharmacy.address,
                  icon: Icons.local_pharmacy_rounded,
                  badges: [
                    if (distanceKm != null)
                      CustomerPill(
                        icon: Icons.near_me_outlined,
                        label: '${distanceKm!.toStringAsFixed(1)} km away',
                      ),
                    CustomerPill(
                      icon: Icons.verified_outlined,
                      label: 'Verified pharmacy',
                    ),
                  ],
                ),
                if (currentPharmacy.reviewCount > 0) ...[
                  const SizedBox(height: 14),
                  CustomerSurfaceCard(
                    child: Row(
                      children: [
                        CustomerIconBadge(
                          icon: Icons.star_rounded,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StarRatingDisplay(
                                rating: currentPharmacy.averageRating,
                                showValue: true,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Based on ${currentPharmacy.reviewCount} reviews',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                CustomerSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 230,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: kIsWeb
                          ? Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE0F2FE),
                                    Color(0xFFCCFBF1),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Map is not available in web builds. Use "Open Maps" to view location.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: position,
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(pharmacy.pharmacyId),
                                  position: position,
                                  infoWindow: InfoWindow(title: pharmacy.name),
                                ),
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomerSurfaceCard(
                  child: Row(
                    children: [
                      CustomerIconBadge(
                        icon: Icons.medication_outlined,
                        color: stock.isAvailable
                            ? Colors.teal.shade700
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.medicineName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stock.isAvailable
                                  ? 'Available • Qty ${stock.quantity} • \$${stock.price.toStringAsFixed(2)}'
                                  : 'Out of stock',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomerSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.call),
                              label: const Text('Call'),
                              onPressed: () => _launch(
                                Uri.parse('tel:${currentPharmacy.phone}'),
                                context,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Maps'),
                              onPressed: () => _launch(
                                Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${currentPharmacy.latitude},${currentPharmacy.longitude}',
                                ),
                                context,
                              ),
                            ),

                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Rate visit'),
                        onPressed: () =>
                            _openVisitReview(context, currentPharmacy),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Subscribe'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateSubscriptionScreen(
                                medicineName: stock.medicineName,
                                medicineId: stock.medicineId,
                                pharmacyId: currentPharmacy.pharmacyId,
                                pharmacyName: currentPharmacy.name,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.event_available_outlined),
                        label: const Text('Reserve for pickup'),
                        onPressed: stock.isAvailable
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReservationScreen(
                                      stock: stock,
                                      pharmacy: currentPharmacy,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PharmacyReviewsSection(pharmacy: currentPharmacy),
              ],
            );
          },
        ),
      ),
    );
  }
}
