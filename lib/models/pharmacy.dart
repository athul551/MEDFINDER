import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacy {
  Pharmacy({
    required this.pharmacyId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.isVerified,
    required this.createdAt,
  });

  final String pharmacyId;
  final String ownerId;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isVerified;
  final DateTime createdAt;

  factory Pharmacy.fromMap(Map<String, dynamic> map, {String? id}) {
    return Pharmacy(
      pharmacyId: id ?? map['pharmacyId'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pharmacyId': pharmacyId,
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Pharmacy copyWith({
    String? name,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isVerified,
  }) {
    return Pharmacy(
      pharmacyId: pharmacyId,
      ownerId: ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}
