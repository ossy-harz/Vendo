import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? productId;
  final String? serviceId;
  final String? offerAmount;
  final String? offerStatus; // pending, accepted, rejected

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
    this.productId,
    this.serviceId,
    this.offerAmount,
    this.offerStatus,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      productId: data['productId'],
      serviceId: data['serviceId'],
      offerAmount: data['offerAmount'],
      offerStatus: data['offerStatus'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'productId': productId,
      'serviceId': serviceId,
      'offerAmount': offerAmount,
      'offerStatus': offerStatus,
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessageText;
  final String? productId;
  final String? productTitle;
  final String? serviceId;
  final String? serviceTitle;
  final bool hasUnreadMessages;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.lastMessageAt,
    required this.lastMessageText,
    this.productId,
    this.productTitle,
    this.serviceId,
    this.serviceTitle,
    required this.hasUnreadMessages,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      lastMessageText: data['lastMessageText'] ?? '',
      productId: data['productId'],
      productTitle: data['productTitle'],
      serviceId: data['serviceId'],
      serviceTitle: data['serviceTitle'],
      hasUnreadMessages: data['hasUnreadMessages'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageText': lastMessageText,
      'productId': productId,
      'productTitle': productTitle,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'hasUnreadMessages': hasUnreadMessages,
    };
  }
}

