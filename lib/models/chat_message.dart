import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.createdAt,
  });

  final String text;
  final bool isUser;
  final bool isError;
  final DateTime? createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }
}
