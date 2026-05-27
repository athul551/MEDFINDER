import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_constants.dart';

class Reservation {
  Reservation({
    required this.reservationId,
    required this.userId,
    required this.pharmacyId,
    required this.medicineId,
    required this.medicineName,
    required this.pharmacyName,
    required this.quantity,
    required this.status,
    required this.reservedAt,
    required this.pickupTime,
    this.prescriptionUrl,
  });

  final String reservationId;
  final String userId;
  final String pharmacyId;
  final String medicineId;
  final String medicineName;
  final String pharmacyName;
  final int quantity;
  final ReservationStatus status;
  final DateTime reservedAt;
  final DateTime pickupTime;
  final String? prescriptionUrl;

  factory Reservation.fromMap(Map<String, dynamic> map, {String? id}) {
    return Reservation(
      reservationId: id ?? map['reservationId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      pharmacyId: map['pharmacyId'] as String? ?? '',
      medicineId: map['medicineId'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      pharmacyName: map['pharmacyName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      status: ReservationStatus.fromString(map['status'] as String? ?? ''),
      reservedAt: (map['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickupTime: (map['pickupTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prescriptionUrl: map['prescriptionUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'userId': userId,
      'pharmacyId': pharmacyId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'pharmacyName': pharmacyName,
      'quantity': quantity,
      'status': status.name,
      'reservedAt': Timestamp.fromDate(reservedAt),
      'pickupTime': Timestamp.fromDate(pickupTime),
      'prescriptionUrl': prescriptionUrl,
    };
  }
}
