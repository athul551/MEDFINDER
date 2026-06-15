import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/customer_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import 'customer_ui.dart';

class MedicineHuntScreen extends StatefulWidget {
  const MedicineHuntScreen({super.key, required this.query});

  final String query;

  @override
  State<MedicineHuntScreen> createState() => _MedicineHuntScreenState();
}

class _MedicineHuntScreenState extends State<MedicineHuntScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().buildMedicineHuntRoute(widget.query);
    });
  }

  Future<void> _openRouteInMaps(CustomerProvider provider) async {
    final stops = provider.huntRoute;
    if (stops.isEmpty) return;

    final origin = provider.currentPosition != null
        ? '${provider.currentPosition!.latitude},${provider.currentPosition!.longitude}'
        : '${stops.first.pharmacy.latitude},${stops.first.pharmacy.longitude}';
    final destination =
        '${stops.last.pharmacy.latitude},${stops.last.pharmacy.longitude}';
    final waypoints = stops
        .take(stops.length - 1)
        .map((s) => '${s.pharmacy.latitude},${s.pharmacy.longitude}')
        .join('|');

    final params = {
      'api': '1',
      'origin': origin,
      'destination': destination,
      if (waypoints.isNotEmpty) 'waypoints': waypoints,
    };
    final uri = Uri.https('www.google.com', '/maps/dir/', params);

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open route in maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final routeSteps = provider.huntRoute;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Medicine Hunt Mode',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: provider.isHuntLoading
            ? const LoadingView(message: 'Building optimized route...')
            : routeSteps.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No route found',
                    message: provider.huntErrorMessage ??
                        'Try a different medicine list or enable location access.',
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomerHeroCard(
                          title: 'Optimized Route',
                          subtitle:
                              'Follow the route below to collect your medicines from the nearest pharmacies.',
                          icon: Icons.route_outlined,
                          badges: [
                            CustomerPill(
                              icon: Icons.pin_drop_outlined,
                              label: '${routeSteps.length} stops',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: ListView.separated(
                            itemCount: routeSteps.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final step = routeSteps[index];
                              final medicines = step.medicines.join(', ');
                              final distanceText = step.distanceKm != null
                                  ? '${step.distanceKm!.toStringAsFixed(1)} km'
                                  : 'Distance unknown';
                              return CustomerSurfaceCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade600,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            step.pharmacy.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      step.pharmacy.address,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.medication_outlined,
                                          size: 16,
                                          color: Colors.teal.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            medicines,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (step.distanceKm != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.near_me_outlined,
                                            size: 16,
                                            color: Colors.teal.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            distanceText,
                                            style: TextStyle(
                                              color: Colors.teal.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text(
                              'Open route in Maps',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () => _openRouteInMaps(provider),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
