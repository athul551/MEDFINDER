import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reservation.dart';
import '../utils/app_constants.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.actions});

  final Reservation reservation;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (reservation.status) {
      ReservationStatus.pending => Colors.orange,
      ReservationStatus.approved => const Color(0xFF00796B),
      ReservationStatus.rejected => Colors.red,
      ReservationStatus.pickedUp => Colors.green,
      ReservationStatus.cancelled => Colors.grey,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                reservation.medicineName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade900,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((0.12 * 255).round()),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                reservation.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoRow(icon: Icons.store_outlined, text: 'Pharmacy: ${reservation.pharmacyName}'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.production_quantity_limits_outlined, text: 'Quantity: ${reservation.quantity}'),
        const SizedBox(height: 6),
        if (reservation.isDelivery) ...[
          _InfoRow(
            icon: Icons.delivery_dining_outlined,
            text: 'Delivery: ${reservation.deliveryAddress ?? 'Address not provided'}',
          ),
          if (reservation.deliveryFee != null && reservation.deliveryFee! > 0) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.monetization_on_outlined,
              text: 'Delivery fee: ₹${reservation.deliveryFee!.toStringAsFixed(0)}',
            ),
          ],
        ] else ...[
          _InfoRow(
            icon: Icons.schedule_outlined,
            text: 'Pickup: ${DateFormat.yMMMd().add_jm().format(reservation.pickupTime)}',
          ),
        ],
        if (reservation.isDelivery && reservation.deliveryNotes != null && reservation.deliveryNotes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.notes_outlined,
            text: 'Note: ${reservation.deliveryNotes}',
          ),
        ],
        if (reservation.prescriptionUrl != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: Colors.teal.shade600),
              const SizedBox(width: 6),
              Text(
                'Prescription uploaded',
                style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ],
        if (actions != null) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions!),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        ),
      ],
    );
  }
}
