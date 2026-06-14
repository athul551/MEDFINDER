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
      showAppSnackBar(context, 'Please sign in to leave a review.', isError: true);
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
      backgroundColor: const Color(0xFFF8FDFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        title: Text(
          pharmacy.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.teal.shade900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<Pharmacy?>(
        stream: context
            .read<FirestoreService>()
            .watchPharmacyById(pharmacy.pharmacyId),
        builder: (context, snapshot) {
          final currentPharmacy = snapshot.data ?? pharmacy;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: kIsWeb
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'Map is not available in web builds. Use "Open Maps" to view location.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPharmacy.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.teal.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentPharmacy.address,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.teal.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${distanceKm!.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (currentPharmacy.reviewCount > 0) ...[
                      const SizedBox(height: 16),
                      StarRatingDisplay(
                        rating: currentPharmacy.averageRating,
                        showValue: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on ${currentPharmacy.reviewCount} reviews',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: stock.isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        color: stock.isAvailable
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.medicineName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stock.isAvailable
                                ? 'Available • Qty ${stock.quantity} • \$${stock.price.toStringAsFixed(2)}'
                                : 'Out of stock',
                            style: TextStyle(
                              color: stock.isAvailable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.call, size: 20),
                      label: const Text('Call', style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                      onPressed: () =>
                          _launch(Uri.parse('tel:${currentPharmacy.phone}'), context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 20),
                      label: const Text('Open Maps', style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                      onPressed: () => _launch(
                        Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${currentPharmacy.latitude},${currentPharmacy.longitude}',
                        ),
                        context,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review_outlined, size: 20),
                      label: const Text('Rate visit', style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                      onPressed: () => _openVisitReview(context, currentPharmacy),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  icon: const Icon(Icons.event_available_outlined, size: 22),
                  label: const Text('Reserve for pickup', style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  )),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: stock.isAvailable
                        ? Colors.teal.shade700
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PharmacyReviewsSection(pharmacy: currentPharmacy),
            ],
          );
        },
      ),
    );
  }
}
