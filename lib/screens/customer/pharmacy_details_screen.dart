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
      appBar: AppBar(title: Text(pharmacy.name)),
      body: StreamBuilder<Pharmacy?>(
        stream: context
            .read<FirestoreService>()
            .watchPharmacyById(pharmacy.pharmacyId),
        builder: (context, snapshot) {
          final currentPharmacy = snapshot.data ?? pharmacy;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
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
              const SizedBox(height: 16),
              Text(
                currentPharmacy.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(currentPharmacy.address),
              if (distanceKm != null)
                Text('${distanceKm!.toStringAsFixed(1)} km away'),
              if (currentPharmacy.reviewCount > 0) ...[
                const SizedBox(height: 8),
                StarRatingDisplay(
                  rating: currentPharmacy.averageRating,
                  showValue: true,
                ),
                Text(
                  'Based on ${currentPharmacy.reviewCount} reviews',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(stock.medicineName),
                  subtitle: Text(
                    stock.isAvailable
                        ? 'Available • Qty ${stock.quantity} • \$${stock.price.toStringAsFixed(2)}'
                        : 'Out of stock',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    onPressed: () =>
                        _launch(Uri.parse('tel:${currentPharmacy.phone}'), context),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open Maps'),
                    onPressed: () => _launch(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${currentPharmacy.latitude},${currentPharmacy.longitude}',
                      ),
                      context,
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Rate visit'),
                    onPressed: () => _openVisitReview(context, currentPharmacy),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              PharmacyReviewsSection(pharmacy: currentPharmacy),
            ],
          );
        },
      ),
    );
  }
}
