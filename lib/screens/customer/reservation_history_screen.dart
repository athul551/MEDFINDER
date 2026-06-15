import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reservation.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/reservation_review_actions.dart';
import 'customer_ui.dart';

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
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Reservation history',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: user == null
            ? const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Not signed in',
                message: 'Please sign in to view reservations.',
              )
            : StreamBuilder<List<Reservation>>(
                stream:
                    context.read<FirestoreService>().watchReservationsForUser(
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
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CustomerHeroCard(
                        title: 'Your medicine pickups',
                        subtitle:
                            'Track ${reservations.length} reservations and review completed visits from one place.',
                        icon: Icons.event_available_rounded,
                        badges: const [
                          CustomerPill(
                            icon: Icons.receipt_long_outlined,
                            label: 'Pickup status',
                          ),
                          CustomerPill(
                            icon: Icons.rate_review_outlined,
                            label: 'Review actions',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...reservations.map(
                        (reservation) => ReservationCard(
                          reservation: reservation,
                          actions: [
                            ReservationReviewActions(
                              reservation: reservation,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
