import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  inappropriate,
  fraud,
  spam,
  prohibited,
  other,
}

class Report {
  final String id;
  final String reporterId;
  final String? productId;
  final String? serviceId;
  final String? userId;
  final ReportReason reason;
  final String description;
  final DateTime timestamp;
  final bool isResolved;
  final String? adminResponse;
  final DateTime? resolvedAt;

  Report({
    required this.id,
    required this.reporterId,
    this.productId,
    this.serviceId,
    this.userId,
    required this.reason,
    required this.description,
    required this.timestamp,
    required this.isResolved,
    this.adminResponse,
    this.resolvedAt,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      productId: data['productId'],
      serviceId: data['serviceId'],
      userId: data['userId'],
      reason: ReportReason.values.firstWhere(
        (e) => e.toString() == 'ReportReason.${data['reason'] ?? 'other'}',
        orElse: () => ReportReason.other,
      ),
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isResolved: data['isResolved'] ?? false,
      adminResponse: data['adminResponse'],
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'productId': productId,
      'serviceId': serviceId,
      'userId': userId,
      'reason': reason.toString().split('.').last,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
      'adminResponse': adminResponse,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}

