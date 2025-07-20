import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/wishlist_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';

class WishlistService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'wishlist';

  // Get user's wishlist
  Stream<List<WishlistItem>> getUserWishlist(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => WishlistItem.fromFirestore(doc)).toList();
    });
  }

  // Check if an item is in the wishlist
  Future<bool> isInWishlist({
    required String userId,
    String? productId,
    String? serviceId,
  }) async {
    if (productId == null && serviceId == null) {
      throw Exception('Either productId or serviceId must be provided');
    }

    Query query = _firestore.collection(_collection).where('userId', isEqualTo: userId);

    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    } else if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Add item to wishlist
  Future<void> addToWishlist({
    required String userId,
    String? productId,
    String? serviceId,
  }) async {
    if (productId == null && serviceId == null) {
      throw Exception('Either productId or serviceId must be provided');
    }

    // Check if already in wishlist
    final isAlreadyInWishlist = await isInWishlist(
      userId: userId,
      productId: productId,
      serviceId: serviceId,
    );

    if (isAlreadyInWishlist) {
      return; // Already in wishlist, no need to add again
    }

    // Add to wishlist
    await _firestore.collection(_collection).add({
      'userId': userId,
      'productId': productId,
      'serviceId': serviceId,
      'addedAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  // Remove item from wishlist
  Future<void> removeFromWishlist({
    required String userId,
    String? productId,
    String? serviceId,
  }) async {
    if (productId == null && serviceId == null) {
      throw Exception('Either productId or serviceId must be provided');
    }

    Query query = _firestore.collection(_collection).where('userId', isEqualTo: userId);

    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    } else if (serviceId != null) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }

    final querySnapshot = await query.get();
    
    if (querySnapshot.docs.isEmpty) {
      return; // Not in wishlist
    }

    // Delete from wishlist
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    notifyListeners();
  }

  // Get wishlist products
  Future<List<Product>> getWishlistProducts(String userId) async {
    final wishlistItems = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('productId', isNull: false)
        .get();

    final List<Product> products = [];
    
    for (final item in wishlistItems.docs) {
      final data = item.data();
      final productId = data['productId'];
      
      if (productId != null) {
        final productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          products.add(Product.fromFirestore(productDoc));
        }
      }
    }

    return products;
  }

  // Get wishlist services
  Future<List<Service>> getWishlistServices(String userId) async {
    final wishlistItems = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('serviceId', isNull: false)
        .get();

    final List<Service> services = [];
    
    for (final item in wishlistItems.docs) {
      final data = item.data();
      final serviceId = data['serviceId'];
      
      if (serviceId != null) {
        final serviceDoc = await _firestore
            .collection('services')
            .doc(serviceId)
            .get();
        
        if (serviceDoc.exists) {
          services.add(Service.fromFirestore(serviceDoc));
        }
      }
    }

    return services;
  }

  // Clear wishlist
  Future<void> clearWishlist(String userId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    notifyListeners();
  }
}

