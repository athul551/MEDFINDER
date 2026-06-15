import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../services/firestore_service.dart';
import '../../widgets/pharmacy_reviews_section.dart';
import '../customer/customer_ui.dart';

class PharmacyReviewsScreen extends StatelessWidget {
  const PharmacyReviewsScreen({super.key, required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pharmacy ratings',
          style: TextStyle(
            color: Colors.teal.shade900,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
      ),
      body: CustomerScreenBackground(
        child: StreamBuilder<Pharmacy?>(
          stream: context
              .read<FirestoreService>()
              .watchPharmacyById(pharmacy.pharmacyId),
          builder: (context, snapshot) {
            final currentPharmacy = snapshot.data ?? pharmacy;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                PharmacyReviewsSection(pharmacy: currentPharmacy),
              ],
            );
          },
        ),
      ),
    );
  }
}
