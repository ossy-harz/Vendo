import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _chatRoomsCollection = 'chatRooms';
  final String _messagesCollection = 'messages';

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  // Create or get existing chat room
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String otherUserId,
    String? productId,
    String? productTitle,
    String? serviceId,
    String? serviceTitle,
  }) async {
    // Check if chat room already exists
    final querySnapshot = await _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in querySnapshot.docs) {
      final chatRoom = ChatRoom.fromFirestore(doc);
      if (chatRoom.participants.contains(otherUserId)) {
        // Chat room exists, update product/service info if provided
        if ((productId != null && productId.isNotEmpty) ||
            (serviceId != null && serviceId.isNotEmpty)) {
          await _firestore.collection(_chatRoomsCollection).doc(doc.id).update({
            'productId': productId,
            'productTitle': productTitle,
            'serviceId': serviceId,
            'serviceTitle': serviceTitle,
          });
        }
        return doc.id;
      }
    }

    // Create new chat room
    final chatRoomData = ChatRoom(
      id: const Uuid().v4(),
      participants: [currentUserId, otherUserId],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      lastMessageText: '',
      productId: productId,
      productTitle: productTitle,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      hasUnreadMessages: false,
    );

    final docRef = await _firestore
        .collection(_chatRoomsCollection)
        .add(chatRoomData.toFirestore());

    return docRef.id;
  }

  // Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? productId,
    String? serviceId,
  }) async {
    // Create message
    final message = ChatMessage(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      productId: productId,
      serviceId: serviceId,
    );

    // Add message to Firestore
    await _firestore.collection(_messagesCollection).add(message.toFirestore());

    // Update chat room
    await _firestore.collection(_chatRoomsCollection).doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
      'lastMessageText': content,
      'hasUnreadMessages': true,
    });

    notifyListeners();
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? productId,
    String? serviceId,
  }) async {
    // Upload image to Firebase Storage
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref().child('chat_images/$chatId/$fileName');
    
    // Upload image
    await ref.putFile(imageFile);
    
    // Get download URL
    final imageUrl = await ref.getDownloadURL();

    // Create message
    final message = ChatMessage(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      content: 'Image',
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
      productId: productId,
      serviceId: serviceId,
    );

    // Add message to Firestore
    await _firestore.collection(_messagesCollection).add(message.toFirestore());

    // Update chat room
    await _firestore.collection(_chatRoomsCollection).doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
      'lastMessageText': 'Image',
      'hasUnreadMessages': true,
    });

    notifyListeners();
  }

  // Send an offer
  Future<void> sendOffer({
    required String chatId,
    required String senderId,
    required String amount,
    String? productId,
    String? serviceId,
  }) async {
    // Create message
    final message = ChatMessage(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      content: 'Offer: \$$amount',
      timestamp: DateTime.now(),
      isRead: false,
      productId: productId,
      serviceId: serviceId,
      offerAmount: amount,
      offerStatus: 'pending',
    );

    // Add message to Firestore
    await _firestore.collection(_messagesCollection).add(message.toFirestore());

    // Update chat room
    await _firestore.collection(_chatRoomsCollection).doc(chatId).update({
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
      'lastMessageText': 'Offer: \$$amount',
      'hasUnreadMessages': true,
    });

    notifyListeners();
  }

  // Update offer status
  Future<void> updateOfferStatus({
    required String messageId,
    required String status,
  }) async {
    await _firestore.collection(_messagesCollection).doc(messageId).update({
      'offerStatus': status,
    });

    notifyListeners();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    // Get unread messages sent by the other user
    final querySnapshot = await _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    // Update each message
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    // Update chat room
    await _firestore.collection(_chatRoomsCollection).doc(chatId).update({
      'hasUnreadMessages': false,
    });

    notifyListeners();
  }

  // Delete chat room
  Future<void> deleteChatRoom(String chatId) async {
    // Delete all messages in the chat room
    final messagesSnapshot = await _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat room
    batch.delete(_firestore.collection(_chatRoomsCollection).doc(chatId));
    await batch.commit();

    notifyListeners();
  }
}

