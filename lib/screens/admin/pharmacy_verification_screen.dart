import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../providers/admin_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

class PharmacyVerificationScreen extends StatelessWidget {
  const PharmacyVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pharmacy>>(
      stream: context.read<FirestoreService>().watchAllPharmacies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading pharmacies...');
        }
        final pharmacies = snapshot.data ?? [];
        if (pharmacies.isEmpty) {
          return const EmptyState(
            icon: Icons.local_pharmacy_outlined,
            title: 'No pharmacy accounts',
            message: 'New pharmacy owner signups will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pharmacies.length,
          itemBuilder: (context, index) {
            final pharmacy = pharmacies[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pharmacy.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Chip(label: Text('Active')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(pharmacy.address),
                    Text(pharmacy.phone),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                          onPressed: () => _confirmRemove(context, pharmacy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, Pharmacy pharmacy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove pharmacy?'),
          content: Text('${pharmacy.name} will be removed from Firestore.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await context.read<AdminProvider>().removePharmacy(pharmacy.pharmacyId);
    }
  }
}
