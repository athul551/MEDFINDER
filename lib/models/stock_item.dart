import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  StockItem({
    required this.stockId,
    required this.pharmacyId,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.price,
    required this.expiryDate,
    required this.isAvailable,
    required this.updatedAt,
  });

  final String stockId;
  final String pharmacyId;
  final String medicineId;
  final String medicineName;
  final int quantity;
  final double price;
  final DateTime expiryDate;
  final bool isAvailable;
  final DateTime updatedAt;

  bool get isLowStock => quantity <= 10;

  bool get isExpiringSoon {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 30;
  }

  factory StockItem.fromMap(Map<String, dynamic> map, {String? id}) {
    return StockItem(
      stockId: id ?? map['stockId'] as String? ?? '',
      pharmacyId: map['pharmacyId'] as String? ?? '',
      medicineId: map['medicineId'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: map['isAvailable'] as bool? ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stockId': stockId,
      'pharmacyId': pharmacyId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'price': price,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isAvailable': isAvailable,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  StockItem copyWith({
    String? medicineName,
    int? quantity,
    double? price,
    DateTime? expiryDate,
    bool? isAvailable,
  }) {
    return StockItem(
      stockId: stockId,
      pharmacyId: pharmacyId,
      medicineId: medicineId,
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      expiryDate: expiryDate ?? this.expiryDate,
      isAvailable: isAvailable ?? this.isAvailable,
      updatedAt: DateTime.now(),
    );
  }
}
