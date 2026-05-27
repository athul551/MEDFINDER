import 'package:flutter/material.dart';

enum UserRole {
  customer,
  pharmacyOwner,
  admin;

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.pharmacyOwner:
        return 'Pharmacy Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get value => name;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }
}

enum ReservationStatus {
  pending,
  approved,
  rejected,
  pickedUp,
  cancelled;

  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.approved:
        return 'Approved';
      case ReservationStatus.rejected:
        return 'Rejected';
      case ReservationStatus.pickedUp:
        return 'Picked up';
      case ReservationStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReservationStatus.pending,
    );
  }
}

class AppColors {
  static const primary = Color(0xFF126B5F);
  static const secondary = Color(0xFF1E88E5);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const surface = Color(0xFFF7FAF9);
}

class AppCollections {
  static const users = 'users';
  static const pharmacies = 'pharmacies';
  static const medicines = 'medicines';
  static const stock = 'stock';
  static const reservations = 'reservations';
  static const notifications = 'notifications';
}
