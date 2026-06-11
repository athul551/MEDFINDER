import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../services/firestore_service.dart';
import '../../widgets/pharmacy_reviews_section.dart';

class PharmacyReviewsScreen extends StatelessWidget {
  const PharmacyReviewsScreen({super.key, required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy ratings')),
      body: StreamBuilder<Pharmacy?>(
        stream: context
            .read<FirestoreService>()
            .watchPharmacyById(pharmacy.pharmacyId),
        builder: (context, snapshot) {
          final currentPharmacy = snapshot.data ?? pharmacy;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PharmacyReviewsSection(pharmacy: currentPharmacy),
            ],
          );
        },
      ),
    );
  }
}
