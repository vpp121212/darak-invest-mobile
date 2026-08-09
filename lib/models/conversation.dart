import 'dart:convert';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      body: json['body']?.toString() ?? '',
      isRead: (json['isRead'] ?? 0) == 1,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Conversation {
  final String id;
  final String otherId;
  final String otherName;
  final String otherPhone;
  final String? propertyId;
  final String? propertyTitle;
  final List<String> images;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unread;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.otherId,
    required this.otherName,
    this.otherPhone = '',
    this.propertyId,
    this.propertyTitle,
    this.images = const [],
    this.lastMessage = '',
    required this.lastMessageAt,
    this.unread = 0,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    return Conversation(
      id: id,
      otherId: (json['otherId'] ?? '').toString(),
      otherName: json['otherName']?.toString() ?? '',
      otherPhone: json['otherPhone']?.toString() ?? '',
      propertyId: json['propertyId']?.toString(),
      propertyTitle: json['propertyTitle']?.toString(),
      images: _images(json['images']),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt:
          DateTime.tryParse(json['lastMessageAt'] ?? '') ?? DateTime.now(),
      unread: (json['unread'] ?? 0),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static List<String> _images(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [value];
    }
    return const [];
  }
}
