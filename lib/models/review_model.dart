import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String? productId;
  final String? serviceId;
  final String sellerId;
  final double rating;
  final String review;
  final DateTime timestamp;
  final List<String> images;
  final bool isVerifiedPurchase;

  Review({
    required this.id,
    required this.userId,
    this.productId,
    this.serviceId,
    required this.sellerId,
    required this.rating,
    required this.review,
    required this.timestamp,
    required this.images,
    required this.isVerifiedPurchase,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'],
      serviceId: data['serviceId'],
      sellerId: data['sellerId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      review: data['review'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'serviceId': serviceId,
      'sellerId': sellerId,
      'rating': rating,
      'review': review,
      'timestamp': Timestamp.fromDate(timestamp),
      'images': images,
      'isVerifiedPurchase': isVerifiedPurchase,
    };
  }
}

