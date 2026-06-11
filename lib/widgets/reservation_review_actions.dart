import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pharmacy.dart';
import '../models/reservation.dart';
import '../providers/app_auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';
import '../screens/customer/write_review_screen.dart';

class ReservationReviewActions extends StatefulWidget {
  const ReservationReviewActions({
    super.key,
    required this.reservation,
  });

  final Reservation reservation;

  @override
  State<ReservationReviewActions> createState() =>
      _ReservationReviewActionsState();
}

class _ReservationReviewActionsState extends State<ReservationReviewActions> {
  Pharmacy? _pharmacy;
  bool _loading = true;
  bool _canRateReservation = false;
  bool _canRatePurchase = false;
  bool _canRateVisit = false;

  @override
  void initState() {
    super.initState();
    _loadEligibility();
  }

  Future<void> _loadEligibility() async {
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final firestore = context.read<FirestoreService>();
    _pharmacy = await firestore.getPharmacy(widget.reservation.pharmacyId);
    if (_pharmacy == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final results = await Future.wait([
      firestore.canReviewPharmacy(
        userId: user.uid,
        pharmacyId: widget.reservation.pharmacyId,
        triggerType: ReviewTrigger.reservation,
        reservationId: widget.reservation.reservationId,
      ),
      firestore.canReviewPharmacy(
        userId: user.uid,
        pharmacyId: widget.reservation.pharmacyId,
        triggerType: ReviewTrigger.purchase,
        reservationId: widget.reservation.reservationId,
      ),
      firestore.canReviewPharmacy(
        userId: user.uid,
        pharmacyId: widget.reservation.pharmacyId,
        triggerType: ReviewTrigger.visit,
      ),
    ]);

    if (mounted) {
      setState(() {
        _canRateReservation = results[0];
        _canRatePurchase = results[1];
        _canRateVisit = results[2];
        _loading = false;
      });
    }
  }

  Future<void> _openReview(ReviewTrigger triggerType) async {
    final pharmacy = _pharmacy;
    if (pharmacy == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          pharmacy: pharmacy,
          triggerType: triggerType,
          reservationId: triggerType == ReviewTrigger.visit
              ? null
              : widget.reservation.reservationId,
        ),
      ),
    );
    if (result == true) {
      await _loadEligibility();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final actions = <Widget>[];

    if (_canRateReservation) {
      actions.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.event_available_outlined, size: 18),
          label: const Text('Rate reservation'),
          onPressed: () => _openReview(ReviewTrigger.reservation),
        ),
      );
    }
    if (_canRatePurchase) {
      actions.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
          label: const Text('Rate purchase'),
          onPressed: () => _openReview(ReviewTrigger.purchase),
        ),
      );
    }
    if (_canRateVisit) {
      actions.add(
        OutlinedButton.icon(
          icon: const Icon(Icons.store_outlined, size: 18),
          label: const Text('Rate visit'),
          onPressed: () => _openReview(ReviewTrigger.visit),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }
}
