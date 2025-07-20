import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/material.dart';
import 'package:vendo/services/category_service.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import '../models/service_model.dart';
import 'product_service.dart';
import 'service_service.dart';
import 'notification_service.dart';

class TransactionService extends ChangeNotifier {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  final String _collection = 'transactions';
  final ProductService _productService;
  final ServiceService _serviceService;
  final NotificationService _notificationService;

  TransactionService({
    required ProductService productService,
    required ServiceService serviceService,
    required NotificationService notificationService, required CategoryService categoryService,
  })  : _productService = productService,
        _serviceService = serviceService,
        _notificationService = notificationService;

  // Get transactions for a user (as buyer or seller)
  Stream<List<Transaction>> getUserTransactions(String userId) {
    return _firestore
        .collection(_collection)
        .where(
      // Using Firestore's new composite filters if available.
      // Adjust as needed based on your Firestore SDK version.
      // For example, you may need to use .where('buyerId', isEqualTo: userId).where('sellerId', isEqualTo: userId)
      // if composite queries are not supported.
      // Here we assume a composite filter is supported.
      // Note: Replace Filter.or(...) with the appropriate query logic if needed.
      // This is a placeholder for your composite query.
      // If your SDK does not support 'or' queries, you might need to use two separate streams.
      // Alternatively, consider using the new Query.where(Filter.or(...)) syntax if supported.
      'buyerId', isEqualTo: userId,
    )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    });
  }

  // Get transactions for a user as buyer
  Stream<List<Transaction>> getBuyerTransactions(String userId) {
    return _firestore
        .collection(_collection)
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    });
  }

  // Get transactions for a user as seller
  Stream<List<Transaction>> getSellerTransactions(String userId) {
    return _firestore
        .collection(_collection)
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    });
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Transaction.fromFirestore(doc);
    }
    return null;
  }

  // Create a product transaction
  Future<String> createProductTransaction({
    required String buyerId,
    required String productId,
    required String paymentMethod,
    required String shippingAddress,
    String? notes,
  }) async {
    // Get product details
    final product = await _productService.getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }

    // Check if product is available
    if (!product.isAvailable) {
      throw Exception('Product is no longer available');
    }

    // Create transaction (custom Transaction model)
    final transaction = Transaction(
      id: '',
      buyerId: buyerId,
      sellerId: product.sellerId,
      productId: productId,
      serviceId: null,
      title: product.title,
      amount: product.price,
      createdAt: DateTime.now(),
      completedAt: null,
      status: TransactionStatus.pending,
      type: TransactionType.product,
      paymentMethod: paymentMethod,
      paymentId: null, // Will be set after payment processing
      notes: notes,
      shippingAddress: shippingAddress,
      trackingNumber: null,
      isReviewed: false,
    );

    // Add to Firestore
    final docRef = await _firestore
        .collection(_collection)
        .add(transaction.toFirestore());

    // Mark product as sold
    await _productService.markProductAsSold(productId);

    // Send notifications
    await _notificationService.createNotification(
      userId: product.sellerId,
      title: 'New Order',
      body: 'Someone purchased your product: ${product.title}',
      type: NotificationType.transaction,
      relatedId: docRef.id,
    );

    await _notificationService.createNotification(
      userId: buyerId,
      title: 'Purchase Confirmed',
      body: 'Your order for ${product.title} has been placed',
      type: NotificationType.transaction,
      relatedId: docRef.id,
    );

    notifyListeners();
    return docRef.id;
  }

  // Create a service transaction
  Future<String> createServiceTransaction({
    required String buyerId,
    required String serviceId,
    required String paymentMethod,
    String? notes,
  }) async {
    // Get service details
    final service = await _serviceService.getServiceById(serviceId);
    if (service == null) {
      throw Exception('Service not found');
    }

    // Check if service is available
    if (!service.isAvailable) {
      throw Exception('Service is no longer available');
    }

    // Create transaction (custom Transaction model)
    final transaction = Transaction(
      id: '',
      buyerId: buyerId,
      sellerId: service.providerId,
      productId: null,
      serviceId: serviceId,
      title: service.title,
      amount: service.price,
      createdAt: DateTime.now(),
      completedAt: null,
      status: TransactionStatus.pending,
      type: TransactionType.service,
      paymentMethod: paymentMethod,
      paymentId: null, // Will be set after payment processing
      notes: notes,
      shippingAddress: null,
      trackingNumber: null,
      isReviewed: false,
    );

    // Add to Firestore
    final docRef = await _firestore
        .collection(_collection)
        .add(transaction.toFirestore());

    // Send notifications
    await _notificationService.createNotification(
      userId: service.providerId,
      title: 'New Service Booking',
      body: 'Someone booked your service: ${service.title}',
      type: NotificationType.transaction,
      relatedId: docRef.id,
    );

    await _notificationService.createNotification(
      userId: buyerId,
      title: 'Booking Confirmed',
      body: 'Your booking for ${service.title} has been placed',
      type: NotificationType.transaction,
      relatedId: docRef.id,
    );

    notifyListeners();
    return docRef.id;
  }

  // Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
    String? trackingNumber,
  }) async {
    final transaction = await getTransactionById(transactionId);
    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    final updates = <String, dynamic>{
      'status': status.toString().split('.').last,
    };

    if (status == TransactionStatus.completed && transaction.completedAt == null) {
      updates['completedAt'] = fs.Timestamp.fromDate(DateTime.now());
    }

    if (trackingNumber != null) {
      updates['trackingNumber'] = trackingNumber;
    }

    await _firestore.collection(_collection).doc(transactionId).update(updates);

    // Send notifications
    String notificationTitle;
    String notificationBody;

    switch (status) {
      case TransactionStatus.processing:
        notificationTitle = 'Order Processing';
        notificationBody = 'Your order for ${transaction.title} is being processed';
        break;
      case TransactionStatus.completed:
        notificationTitle = 'Order Completed';
        notificationBody = 'Your order for ${transaction.title} has been completed';
        break;
      case TransactionStatus.cancelled:
        notificationTitle = 'Order Cancelled';
        notificationBody = 'Your order for ${transaction.title} has been cancelled';
        break;
      case TransactionStatus.refunded:
        notificationTitle = 'Order Refunded';
        notificationBody = 'Your order for ${transaction.title} has been refunded';
        break;
      default:
        notificationTitle = 'Order Update';
        notificationBody = 'Your order for ${transaction.title} has been updated';
    }

    await _notificationService.createNotification(
      userId: transaction.buyerId,
      title: notificationTitle,
      body: notificationBody,
      type: NotificationType.transaction,
      relatedId: transactionId,
    );

    if (trackingNumber != null) {
      await _notificationService.createNotification(
        userId: transaction.buyerId,
        title: 'Tracking Number Added',
        body: 'Tracking number for your order: $trackingNumber',
        type: NotificationType.transaction,
        relatedId: transactionId,
      );
    }

    notifyListeners();
  }

  // Add review for a transaction
  Future<void> addReview({
    required String transactionId,
    required double rating,
    required String review,
  }) async {
    final transaction = await getTransactionById(transactionId);
    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    // Mark transaction as reviewed
    await _firestore.collection(_collection).doc(transactionId).update({
      'isReviewed': true,
    });

    // Add review to product or service
    if (transaction.productId != null) {
      // Add review to product
      await _firestore.collection('reviews').add({
        'productId': transaction.productId,
        'userId': transaction.buyerId,
        'sellerId': transaction.sellerId,
        'rating': rating,
        'review': review,
        'timestamp': fs.FieldValue.serverTimestamp(),
      });

      // Send notification to seller
      await _notificationService.createNotification(
        userId: transaction.sellerId,
        title: 'New Review',
        body: 'Someone left a review for your product',
        type: NotificationType.review,
        relatedId: transaction.productId,
      );
    } else if (transaction.serviceId != null) {
      // Add review to service
      await _firestore.collection('reviews').add({
        'serviceId': transaction.serviceId,
        'userId': transaction.buyerId,
        'providerId': transaction.sellerId,
        'rating': rating,
        'review': review,
        'timestamp': fs.FieldValue.serverTimestamp(),
      });

      // Send notification to provider
      await _notificationService.createNotification(
        userId: transaction.sellerId,
        title: 'New Review',
        body: 'Someone left a review for your service',
        type: NotificationType.review,
        relatedId: transaction.serviceId,
      );
    }

    notifyListeners();
  }
}
