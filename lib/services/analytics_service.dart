import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get products count
      final productsQuery = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      // Get services count
      final servicesQuery = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: userId)
          .get();
      
      // Get sold products count
      final soldProductsQuery = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .where('isAvailable', isEqualTo: false)
          .get();
      
      // Get transactions as seller
      final sellerTransactionsQuery = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      // Get transactions as buyer
      final buyerTransactionsQuery = await _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: userId)
          .get();
      
      // Calculate total earnings
      double totalEarnings = 0;
      for (final doc in sellerTransactionsQuery.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalEarnings += (data['amount'] ?? 0).toDouble();
        }
      }
      
      // Calculate total spent
      double totalSpent = 0;
      for (final doc in buyerTransactionsQuery.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalSpent += (data['amount'] ?? 0).toDouble();
        }
      }
      
      // Get average rating
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('sellerId', isEqualTo: userId)
          .get();
      
      double averageRating = 0;
      if (reviewsQuery.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in reviewsQuery.docs) {
          totalRating += (doc.data()['rating'] ?? 0).toDouble();
        }
        averageRating = totalRating / reviewsQuery.docs.length;
      }
      
      return {
        'productsCount': productsQuery.docs.length,
        'servicesCount': servicesQuery.docs.length,
        'soldProductsCount': soldProductsQuery.docs.length,
        'sellerTransactionsCount': sellerTransactionsQuery.docs.length,
        'buyerTransactionsCount': buyerTransactionsQuery.docs.length,
        'totalEarnings': totalEarnings,
        'totalSpent': totalSpent,
        'reviewsCount': reviewsQuery.docs.length,
        'averageRating': averageRating,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }
  
  // Get product view analytics
  Future<Map<String, dynamic>> getProductViewAnalytics(String productId) async {
    try {
      final productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (!productDoc.exists) {
        return {};
      }
      
      final data = productDoc.data()!;
      
      // Get view history (if implemented)
      final viewHistoryQuery = await _firestore
          .collection('product_views')
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      
      // Group views by date for the last 30 days
      final Map<String, int> viewsByDate = {};
      final now = DateTime.now();
      
      for (int i = 0; i < 30; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final dateString = '${date.year}-${date.month}-${date.day}';
        viewsByDate[dateString] = 0;
      }
      
      for (final doc in viewHistoryQuery.docs) {
        final viewData = doc.data();
        final timestamp = (viewData['timestamp'] as Timestamp).toDate();
        final dateString = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
        
        if (viewsByDate.containsKey(dateString)) {
          viewsByDate[dateString] = (viewsByDate[dateString] ?? 0) + 1;
        }
      }
      
      return {
        'totalViews': data['viewCount'] ?? 0,
        'viewsByDate': viewsByDate,
      };
    } catch (e) {
      print('Error getting product view analytics: $e');
      return {};
    }
  }
  
  // Record product view
  Future<void> recordProductView(String productId, String userId) async {
    try {
      // Update product view count
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
      
      // Record view in history
      await _firestore
          .collection('product_views')
          .add({
        'productId': productId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording product view: $e');
    }
  }
  
  // Get service view analytics
  Future<Map<String, dynamic>> getServiceViewAnalytics(String serviceId) async {
    try {
      final serviceDoc = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();
      
      if (!serviceDoc.exists) {
        return {};
      }
      
      final data = serviceDoc.data()!;
      
      // Get view history (if implemented)
      final viewHistoryQuery = await _firestore
          .collection('service_views')
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      
      // Group views by date for the last 30 days
      final Map<String, int> viewsByDate = {};
      final now = DateTime.now();
      
      for (int i = 0; i < 30; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final dateString = '${date.year}-${date.month}-${date.day}';
        viewsByDate[dateString] = 0;
      }
      
      for (final doc in viewHistoryQuery.docs) {
        final viewData = doc.data();
        final timestamp = (viewData['timestamp'] as Timestamp).toDate();
        final dateString = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
        
        if (viewsByDate.containsKey(dateString)) {
          viewsByDate[dateString] = (viewsByDate[dateString] ?? 0) + 1;
        }
      }
      
      return {
        'totalViews': data['viewCount'] ?? 0,
        'viewsByDate': viewsByDate,
      };
    } catch (e) {
      print('Error getting service view analytics: $e');
      return {};
    }
  }
  
  // Record service view
  Future<void> recordServiceView(String serviceId, String userId) async {
    try {
      // Update service view count
      await _firestore
          .collection('services')
          .doc(serviceId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
      
      // Record view in history
      await _firestore
          .collection('service_views')
          .add({
        'serviceId': serviceId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording service view: $e');
    }
  }
}

