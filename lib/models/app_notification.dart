import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  final String notificationId;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? id}) {
    return AppNotification(
      notificationId: id ?? map['notificationId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
