import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import 'notification_service.dart';

class ReviewService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService;
  final String _collection = 'reviews';

  ReviewService({required NotificationService notificationService})
      : _notificationService = notificationService;

  // Get reviews for a product
  Stream<List<Review>> getProductReviews(String productId) {
    return _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Get reviews for a service
  Stream<List<Review>> getServiceReviews(String serviceId) {
    return _firestore
        .collection(_collection)
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Get reviews by a user
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Get reviews for a seller
  Stream<List<Review>> getSellerReviews(String sellerId) {
    return _firestore
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    });
  }

  // Get average rating for a product
  Future<double> getProductAverageRating(String productId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0;
    for (final doc in querySnapshot.docs) {
      final review = Review.fromFirestore(doc);
      totalRating += review.rating;
    }

    return totalRating / querySnapshot.docs.length;
  }

  // Get average rating for a service
  Future<double> getServiceAverageRating(String serviceId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('serviceId', isEqualTo: serviceId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0;
    for (final doc in querySnapshot.docs) {
      final review = Review.fromFirestore(doc);
      totalRating += review.rating;
    }

    return totalRating / querySnapshot.docs.length;
  }

  // Get average rating for a seller
  Future<double> getSellerAverageRating(String sellerId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0;
    for (final doc in querySnapshot.docs) {
      final review = Review.fromFirestore(doc);
      totalRating += review.rating;
    }

    return totalRating / querySnapshot.docs.length;
  }

  // Add a review
  Future<String> addReview({
    required String userId,
    String? productId,
    String? serviceId,
    required String sellerId,
    required double rating,
    required String review,
    List<File>? images,
    bool isVerifiedPurchase = false,
  }) async {
    if (productId == null && serviceId == null) {
      throw Exception('Either productId or serviceId must be provided');
    }

    // Check if user has already reviewed this product/service
    final existingReview = await _checkExistingReview(
      userId: userId,
      productId: productId,
      serviceId: serviceId,
    );

    if (existingReview != null) {
      throw Exception('You have already reviewed this item');
    }

    // Upload images if provided
    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      imageUrls = await _uploadReviewImages(images, productId ?? serviceId!);
    }

    // Create review
    final reviewData = Review(
      id: const Uuid().v4(),
      userId: userId,
      productId: productId,
      serviceId: serviceId,
      sellerId: sellerId,
      rating: rating,
      review: review,
      timestamp: DateTime.now(),
      images: imageUrls,
      isVerifiedPurchase: isVerifiedPurchase,
    );

    // Add to Firestore
    final docRef = await _firestore
        .collection(_collection)
        .add(reviewData.toFirestore());

    // Send notification to seller
    await _notificationService.createNotification(
      userId: sellerId,
      title: 'New Review',
      body: 'Someone left a review for your ${productId != null ? 'product' : 'service'}',
      type: NotificationType.review,
      relatedId: docRef.id,
      data: {
        'productId': productId,
        'serviceId': serviceId,
      },
    );

    notifyListeners();
    return docRef.id;
  }

  // Update a review
  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String review,
    List<File>? newImages,
  }) async {
    // Get the current review
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    if (!doc.exists) {
      throw Exception('Review not found');
    }

    final currentReview = Review.fromFirestore(doc);
    List<String> imageUrls = List.from(currentReview.images);

    // Upload new images if provided
    if (newImages != null && newImages.isNotEmpty) {
      final itemId = currentReview.productId ?? currentReview.serviceId!;
      final newUrls = await _uploadReviewImages(newImages, itemId);
      imageUrls.addAll(newUrls);
    }

    // Update review
    await _firestore.collection(_collection).doc(reviewId).update({
      'rating': rating,
      'review': review,
      'images': imageUrls,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });

    notifyListeners();
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    // Get the review to access its images
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    if (!doc.exists) {
      throw Exception('Review not found');
    }

    final review = Review.fromFirestore(doc);

    // Delete the review document
    await _firestore.collection(_collection).doc(reviewId).delete();

    // Delete associated images
    for (final imageUrl in review.images) {
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        print('Error deleting image: $e');
      }
    }

    notifyListeners();
  }

  // Helper method to check if user has already reviewed this product/service
  Future<Review?> _checkExistingReview({
    required String userId,
    String? productId,
    String? serviceId,
  }) async {
    Query query = _firestore.collection(_collection).where('userId', isEqualTo: userId);

    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    } else if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }

    final querySnapshot = await query.get();
    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return Review.fromFirestore(querySnapshot.docs.first);
  }

  // Helper method to upload review images
  Future<List<String>> _uploadReviewImages(List<File> images, String itemId) async {
    final List<String> imageUrls = [];

    for (final image in images) {
      final uuid = const Uuid().v4();
      final path = 'reviews/$itemId/$uuid.jpg';
      final ref = _storage.ref().child(path);

      // Upload image
      await ref.putFile(image);

      // Get download URL
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }

    return imageUrls;
  }
}

