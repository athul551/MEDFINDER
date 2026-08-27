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
    this.isDelivery = false,
    this.deliveryAddress,
    this.deliveryFee,
    this.deliveryNotes,
    this.unitPrice = 0,
    this.totalAmount = 0,
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
  final bool isDelivery;
  final String? deliveryAddress;
  final double? deliveryFee;
  final String? deliveryNotes;
  final double unitPrice;
  final double totalAmount;

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
      isDelivery: map['isDelivery'] as bool? ?? false,
      deliveryAddress: map['deliveryAddress'] as String?,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble(),
      deliveryNotes: map['deliveryNotes'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
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
      'isDelivery': isDelivery,
      'deliveryAddress': deliveryAddress,
      'deliveryFee': deliveryFee,
      'deliveryNotes': deliveryNotes,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }
}
