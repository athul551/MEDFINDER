import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../../models/pharmacy.dart';
import '../../models/stock_item.dart';
import '../../utils/snackbars.dart';
import 'reservation_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final position = LatLng(pharmacy.latitude, pharmacy.longitude);
    return Scaffold(
      appBar: AppBar(title: Text(pharmacy.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          Text(pharmacy.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(pharmacy.address),
          if (distanceKm != null)
            Text('${distanceKm!.toStringAsFixed(1)} km away'),
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
                    _launch(Uri.parse('tel:${pharmacy.phone}'), context),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open Maps'),
                onPressed: () => _launch(
                  Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${pharmacy.latitude},${pharmacy.longitude}',
                  ),
                  context,
                ),
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
                        builder: (_) =>
                            ReservationScreen(stock: stock, pharmacy: pharmacy),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
