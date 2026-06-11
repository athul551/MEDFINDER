import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_constants.dart';
import 'pharmacy.dart';

class PharmacyReview {
  PharmacyReview({
    required this.reviewId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.userId,
    required this.userName,
    required this.triggerType,
    required this.overallRating,
    required this.availabilityRating,
    required this.pricingRating,
    required this.serviceRating,
    required this.deliveryRating,
    required this.comment,
    required this.createdAt,
    this.reservationId,
  });

  final String reviewId;
  final String pharmacyId;
  final String pharmacyName;
  final String userId;
  final String userName;
  final ReviewTrigger triggerType;
  final String? reservationId;
  final int overallRating;
  final int availabilityRating;
  final int pricingRating;
  final int serviceRating;
  final int deliveryRating;
  final String comment;
  final DateTime createdAt;

  static int computeOverallRating({
    required int availabilityRating,
    required int pricingRating,
    required int serviceRating,
    required int deliveryRating,
  }) {
    return ((availabilityRating +
                pricingRating +
                serviceRating +
                deliveryRating) /
            4)
        .round()
        .clamp(1, 5);
  }

  factory PharmacyReview.fromMap(Map<String, dynamic> map, {String? id}) {
    return PharmacyReview(
      reviewId: id ?? map['reviewId'] as String? ?? '',
      pharmacyId: map['pharmacyId'] as String? ?? '',
      pharmacyName: map['pharmacyName'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      triggerType: ReviewTrigger.fromString(
        map['triggerType'] as String? ?? '',
      ),
      reservationId: map['reservationId'] as String?,
      overallRating: (map['overallRating'] as num?)?.toInt() ?? 1,
      availabilityRating: (map['availabilityRating'] as num?)?.toInt() ?? 1,
      pricingRating: (map['pricingRating'] as num?)?.toInt() ?? 1,
      serviceRating: (map['serviceRating'] as num?)?.toInt() ?? 1,
      deliveryRating: (map['deliveryRating'] as num?)?.toInt() ?? 1,
      comment: map['comment'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'userId': userId,
      'userName': userName,
      'triggerType': triggerType.value,
      'reservationId': reservationId,
      'overallRating': overallRating,
      'availabilityRating': availabilityRating,
      'pricingRating': pricingRating,
      'serviceRating': serviceRating,
      'deliveryRating': deliveryRating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class PharmacyRatingSummary {
  const PharmacyRatingSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.availabilityAvg,
    required this.pricingAvg,
    required this.serviceAvg,
    required this.deliveryAvg,
  });

  final double averageRating;
  final int reviewCount;
  final double availabilityAvg;
  final double pricingAvg;
  final double serviceAvg;
  final double deliveryAvg;

  static const empty = PharmacyRatingSummary(
    averageRating: 0,
    reviewCount: 0,
    availabilityAvg: 0,
    pricingAvg: 0,
    serviceAvg: 0,
    deliveryAvg: 0,
  );

  factory PharmacyRatingSummary.fromPharmacy(Pharmacy pharmacy) {
    return PharmacyRatingSummary(
      averageRating: pharmacy.averageRating,
      reviewCount: pharmacy.reviewCount,
      availabilityAvg: pharmacy.availabilityAvg,
      pricingAvg: pharmacy.pricingAvg,
      serviceAvg: pharmacy.serviceAvg,
      deliveryAvg: pharmacy.deliveryAvg,
    );
  }
}
