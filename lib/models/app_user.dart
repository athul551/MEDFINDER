import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_constants.dart';

class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.profileImageUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final String? profileImageUrl;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? ''),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }
    return data;
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
