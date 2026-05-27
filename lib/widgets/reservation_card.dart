import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reservation.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.actions});

  final Reservation reservation;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
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
                    reservation.medicineName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(reservation.status.label)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pharmacy: ${reservation.pharmacyName}'),
            Text('Quantity: ${reservation.quantity}'),
            Text(
              'Pickup: ${DateFormat.yMMMd().add_jm().format(reservation.pickupTime)}',
            ),
            if (reservation.prescriptionUrl != null) ...[
              const SizedBox(height: 6),
              const Text('Prescription uploaded'),
            ],
            if (actions != null) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}
