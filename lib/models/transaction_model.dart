import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  pending,
  processing,
  completed,
  cancelled,
  refunded,
}

enum TransactionType {
  product,
  service,
}

class Transaction {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? productId;
  final String? serviceId;
  final String title;
  final double amount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final TransactionStatus status;
  final TransactionType type;
  final String? paymentMethod;
  final String? paymentId;
  final String? notes;
  final String? shippingAddress;
  final String? trackingNumber;
  final bool isReviewed;

  Transaction({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.productId,
    this.serviceId,
    required this.title,
    required this.amount,
    required this.createdAt,
    this.completedAt,
    required this.status,
    required this.type,
    this.paymentMethod,
    this.paymentId,
    this.notes,
    this.shippingAddress,
    this.trackingNumber,
    required this.isReviewed,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      productId: data['productId'],
      serviceId: data['serviceId'],
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status'] ?? 'pending'}',
        orElse: () => TransactionStatus.pending,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type'] ?? 'product'}',
        orElse: () => TransactionType.product,
      ),
      paymentMethod: data['paymentMethod'],
      paymentId: data['paymentId'],
      notes: data['notes'],
      shippingAddress: data['shippingAddress'],
      trackingNumber: data['trackingNumber'],
      isReviewed: data['isReviewed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'serviceId': serviceId,
      'title': title,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'notes': notes,
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
      'isReviewed': isReviewed,
    };
  }
}

