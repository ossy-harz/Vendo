import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String? productId;
  final String? serviceId;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.userId,
    this.productId,
    this.serviceId,
    required this.addedAt,
  });

  factory WishlistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WishlistItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'],
      serviceId: data['serviceId'],
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'serviceId': serviceId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}

