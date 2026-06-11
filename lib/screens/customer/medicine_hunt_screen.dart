import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/customer_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

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
      appBar: AppBar(
        title: const Text('Medicine Hunt Mode'),
      ),
      body: provider.isHuntLoading
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
                      const Text(
                        'Optimized route',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow the route below to collect your medicines from the nearest pharmacies.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
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
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stop ${index + 1}: ${step.pharmacy.name}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(step.pharmacy.address),
                                    const SizedBox(height: 8),
                                    Text('Medicines: $medicines'),
                                    if (step.distanceKm != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                        ),
                                        child: Text(
                                          'Distance: $distanceText',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('Open route in Maps'),
                        onPressed: () => _openRouteInMaps(provider),
                      ),
                    ],
                  ),
                ),
    );
  }
}
