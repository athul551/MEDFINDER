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
    this.averageRating = 0,
    this.reviewCount = 0,
    this.availabilityAvg = 0,
    this.pricingAvg = 0,
    this.serviceAvg = 0,
    this.deliveryAvg = 0,
    this.deliveryAvailable = false,
    this.deliveryFee = 0,
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
  final double averageRating;
  final int reviewCount;
  final double availabilityAvg;
  final double pricingAvg;
  final double serviceAvg;
  final double deliveryAvg;
  final bool deliveryAvailable;
  final double deliveryFee;

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
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      availabilityAvg: (map['availabilityAvg'] as num?)?.toDouble() ?? 0,
      pricingAvg: (map['pricingAvg'] as num?)?.toDouble() ?? 0,
      serviceAvg: (map['serviceAvg'] as num?)?.toDouble() ?? 0,
      deliveryAvg: (map['deliveryAvg'] as num?)?.toDouble() ?? 0,
      deliveryAvailable: map['deliveryAvailable'] as bool? ?? false,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
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
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'availabilityAvg': availabilityAvg,
      'pricingAvg': pricingAvg,
      'serviceAvg': serviceAvg,
      'deliveryAvg': deliveryAvg,
      'deliveryAvailable': deliveryAvailable,
      'deliveryFee': deliveryFee,
    };
  }

  Pharmacy copyWith({
    String? name,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    bool? isVerified,
    double? averageRating,
    int? reviewCount,
    double? availabilityAvg,
    double? pricingAvg,
    double? serviceAvg,
    double? deliveryAvg,
    bool? deliveryAvailable,
    double? deliveryFee,
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
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      availabilityAvg: availabilityAvg ?? this.availabilityAvg,
      pricingAvg: pricingAvg ?? this.pricingAvg,
      serviceAvg: serviceAvg ?? this.serviceAvg,
      deliveryAvg: deliveryAvg ?? this.deliveryAvg,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}
