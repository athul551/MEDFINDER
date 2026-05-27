import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/reservation.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/reservation_card.dart';

class ReservationsManagementScreen extends StatelessWidget {
  const ReservationsManagementScreen({super.key, required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage reservations')),
      body: StreamBuilder<List<Reservation>>(
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
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return ReservationCard(
                reservation: reservation,
                actions: [
                  if (reservation.status == ReservationStatus.pending)
                    FilledButton(
                      onPressed: () => _setStatus(
                        context,
                        reservation,
                        ReservationStatus.approved,
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
                      child: const Text('Reject'),
                    ),
                  if (reservation.status == ReservationStatus.approved)
                    FilledButton(
                      onPressed: () => _setStatus(
                        context,
                        reservation,
                        ReservationStatus.pickedUp,
                      ),
                      child: const Text('Picked up'),
                    ),
                ],
              );
            },
          );
        },
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
