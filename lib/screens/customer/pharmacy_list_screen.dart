import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

class PharmacyListScreen extends StatelessWidget {
  const PharmacyListScreen({super.key});

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
                child: ListTile(
                  leading: const Icon(Icons.local_pharmacy_outlined),
                  title: Text(pharmacy.name),
                  subtitle: Text(pharmacy.address),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
