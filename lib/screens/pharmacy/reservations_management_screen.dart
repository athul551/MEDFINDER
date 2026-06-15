import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/reservation.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/reservation_card.dart';
import '../customer/customer_ui.dart';

class ReservationsManagementScreen extends StatelessWidget {
  const ReservationsManagementScreen({super.key, required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage reservations',
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
        child: StreamBuilder<List<Reservation>>(
          stream: context.read<FirestoreService>().watchReservationsForPharmacy(
                pharmacy.pharmacyId,
              ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load reservations',
                message: snapshot.error.toString(),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading reservations...');
            }
            final reservations = snapshot.data ?? [];
            if (reservations.isEmpty) {
              return const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No reservations',
                message: 'Customer reservation requests will appear here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomerSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: ReservationCard(
                      reservation: reservation,
                      actions: [
                        if (reservation.status == ReservationStatus.pending)
                          FilledButton(
                            onPressed: () => _setStatus(
                              context,
                              reservation,
                              ReservationStatus.approved,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                            ),
                            child: const Text('Approve'),
                          ),
                        if (reservation.status == ReservationStatus.pending)
                          OutlinedButton(
                            onPressed: () => _setStatus(
                              context,
                              reservation,
                              ReservationStatus.rejected,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                            child: const Text('Reject'),
                          ),
                        if (reservation.status == ReservationStatus.approved)
                          FilledButton(
                            onPressed: () => _setStatus(
                              context,
                              reservation,
                              ReservationStatus.pickedUp,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                            ),
                            child: const Text('Picked up'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    Reservation reservation,
    ReservationStatus status,
  ) {
    return context.read<FirestoreService>().updateReservationStatus(
          reservation.reservationId,
          status,
        );
  }
}
