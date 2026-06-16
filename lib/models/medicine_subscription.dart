import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineSubscription {
  MedicineSubscription({
    required this.subscriptionId,
    required this.userId,
    required this.medicineName,
    this.medicineId,
    this.pharmacyId,
    this.pharmacyName,
    required this.frequencyDays,
    required this.quantity,
    required this.nextRefillDate,
    this.lastRefillDate,
    this.autoReminder = true,
    this.autoReservation = false,
    this.isActive = true,
    required this.createdAt,
  });

  final String subscriptionId;
  final String userId;
  final String medicineName;
  final String? medicineId;
  final String? pharmacyId;
  final String? pharmacyName;
  final int frequencyDays;
  final int quantity;
  final DateTime nextRefillDate;
  final DateTime? lastRefillDate;
  final bool autoReminder;
  final bool autoReservation;
  final bool isActive;
  final DateTime createdAt;

  SubscriptionStatus get status {
    if (!isActive) return SubscriptionStatus.inactive;
    final daysLeft = nextRefillDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return SubscriptionStatus.refillDue;
    if (daysLeft <= 3) return SubscriptionStatus.refillDue;
    if (daysLeft <= 7) return SubscriptionStatus.upcoming;
    return SubscriptionStatus.active;
  }

  int get daysRemaining {
    return nextRefillDate.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  double get estimatedStockRemaining {
    if (lastRefillDate == null) return 100;
    final total = frequencyDays;
    final elapsed = DateTime.now().difference(lastRefillDate!).inDays;
    final remaining = ((total - elapsed) / total) * 100;
    return remaining.clamp(0, 100);
  }

  factory MedicineSubscription.fromMap(Map<String, dynamic> map,
      {String? id}) {
    return MedicineSubscription(
      subscriptionId: id ?? map['subscriptionId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      medicineId: map['medicineId'] as String?,
      pharmacyId: map['pharmacyId'] as String?,
      pharmacyName: map['pharmacyName'] as String?,
      frequencyDays: (map['frequencyDays'] as num?)?.toInt() ?? 30,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      nextRefillDate:
          (map['nextRefillDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastRefillDate: (map['lastRefillDate'] as Timestamp?)?.toDate(),
      autoReminder: map['autoReminder'] as bool? ?? true,
      autoReservation: map['autoReservation'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'userId': userId,
      'medicineName': medicineName,
      'medicineId': medicineId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'frequencyDays': frequencyDays,
      'quantity': quantity,
      'nextRefillDate': Timestamp.fromDate(nextRefillDate),
      'lastRefillDate':
          lastRefillDate != null ? Timestamp.fromDate(lastRefillDate!) : null,
      'autoReminder': autoReminder,
      'autoReservation': autoReservation,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MedicineSubscription copyWith({
    String? medicineName,
    String? medicineId,
    String? pharmacyId,
    String? pharmacyName,
    int? frequencyDays,
    int? quantity,
    DateTime? nextRefillDate,
    DateTime? lastRefillDate,
    bool? autoReminder,
    bool? autoReservation,
    bool? isActive,
  }) {
    return MedicineSubscription(
      subscriptionId: subscriptionId,
      userId: userId,
      medicineName: medicineName ?? this.medicineName,
      medicineId: medicineId ?? this.medicineId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      quantity: quantity ?? this.quantity,
      nextRefillDate: nextRefillDate ?? this.nextRefillDate,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
      autoReminder: autoReminder ?? this.autoReminder,
      autoReservation: autoReservation ?? this.autoReservation,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

enum SubscriptionStatus { active, upcoming, refillDue, inactive }
