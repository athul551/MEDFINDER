import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reservation.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/reservation_review_actions.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Checking authentication...'),
      );
    }

    final user = auth.appUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation history')),
      body: user == null
          ? const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Not signed in',
              message: 'Please sign in to view reservations.',
            )
          : StreamBuilder<List<Reservation>>(
              stream: context.read<FirestoreService>().watchReservationsForUser(
                    user.uid,
                  ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to load history',
                    message: snapshot.error.toString(),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading history...');
                }
                final reservations = snapshot.data ?? [];
                if (reservations.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No reservations',
                    message: 'Reserved medicines will appear here.',
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
                        ReservationReviewActions(reservation: reservation),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
