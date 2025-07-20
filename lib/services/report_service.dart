import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Create a report
  Future<String> createReport({
    required String reporterId,
    String? productId,
    String? serviceId,
    String? userId,
    required ReportReason reason,
    required String description,
  }) async {
    if (productId == null && serviceId == null && userId == null) {
      throw Exception('At least one of productId, serviceId, or userId must be provided');
    }

    // Create report
    final report = Report(
      id: '',
      reporterId: reporterId,
      productId: productId,
      serviceId: serviceId,
      userId: userId,
      reason: reason,
      description: description,
      timestamp: DateTime.now(),
      isResolved: false,
      adminResponse: null,
      resolvedAt: null,
    );

    // Add to Firestore
    final docRef = await _firestore
        .collection(_collection)
        .add(report.toFirestore());

    notifyListeners();
    return docRef.id;
  }

  // Get reports by reporter
  Stream<List<Report>> getReportsByReporter(String reporterId) {
    return _firestore
        .collection(_collection)
        .where('reporterId', isEqualTo: reporterId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Get reports for a product
  Stream<List<Report>> getProductReports(String productId) {
    return _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Get reports for a service
  Stream<List<Report>> getServiceReports(String serviceId) {
    return _firestore
        .collection(_collection)
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Get reports for a user
  Stream<List<Report>> getUserReports(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
    });
  }

  // Update report status (for admin use)
  Future<void> updateReportStatus({
    required String reportId,
    required bool isResolved,
    String? adminResponse,
  }) async {
    final updates = <String, dynamic>{
      'isResolved': isResolved,
    };

    if (isResolved) {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
    }

    if (adminResponse != null) {
      updates['adminResponse'] = adminResponse;
    }

    await _firestore
        .collection(_collection)
        .doc(reportId)
        .update(updates);

    notifyListeners();
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    await _firestore
        .collection(_collection)
        .doc(reportId)
        .delete();

    notifyListeners();
  }
}

