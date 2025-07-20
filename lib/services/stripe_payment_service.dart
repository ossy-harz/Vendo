import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StripePaymentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _apiUrl = 'https://api.stripe.com/v1';
  final String _publishableKey = 'pk_test_your_publishable_key';
  final String _secretKey = 'sk_test_your_secret_key';
  
  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
    required String customerId,
    String? description,
  }) async {
    try {
      // In a real app, this would be done on your server
      // For demo purposes, we're doing it here (not recommended for production)
      
      final Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'customer': customerId,
        'description': description,
      };
      
      final response = await http.post(
        Uri.parse('$_apiUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating payment intent: $e');
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Create customer
  Future<Map<String, dynamic>> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      // In a real app, this would be done on your server
      
      final Map<String, dynamic> body = {
        'email': email,
        'name': name,
      };
      
      final response = await http.post(
        Uri.parse('$_apiUrl/customers'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Error creating customer: $e');
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Add payment method to customer
  Future<Map<String, dynamic>> addPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    try {
      // In a real app, this would be done on your server
      
      final response = await http.post(
        Uri.parse('$_apiUrl/payment_methods/$paymentMethodId/attach'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Error adding payment method: $e');
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Process payment
  Future<Map<String, dynamic>> processPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      // In a real app, this would be done on your server
      
      final response = await http.post(
        Uri.parse('$_apiUrl/payment_intents/$paymentIntentId/confirm'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method': paymentMethodId,
        },
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Error processing payment: $e');
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Save payment method for user
  Future<void> savePaymentMethod({
    required String userId,
    required String paymentMethodId,
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .add({
        'paymentMethodId': paymentMethodId,
        'brand': brand,
        'last4': last4,
        'expMonth': expMonth,
        'expYear': expYear,
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving payment method: $e');
    }
  }
  
  // Get user's payment methods
  Future<List<Map<String, dynamic>>> getUserPaymentMethods(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
          .toList();
    } catch (e) {
      print('Error getting user payment methods: $e');
      return [];
    }
  }
  
  // Set default payment method
  Future<void> setDefaultPaymentMethod({
    required String userId,
    required String paymentMethodId,
  }) async {
    try {
      // First, set all payment methods to non-default
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      // Then set the selected one as default
      final paymentMethodDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .where('paymentMethodId', isEqualTo: paymentMethodId)
          .get();
      
      if (paymentMethodDoc.docs.isNotEmpty) {
        batch.update(paymentMethodDoc.docs.first.reference, {'isDefault': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error setting default payment method: $e');
    }
  }
  
  // Delete payment method
  Future<void> deletePaymentMethod({
    required String userId,
    required String paymentMethodId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payment_methods')
          .where('paymentMethodId', isEqualTo: paymentMethodId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      print('Error deleting payment method: $e');
    }
  }
}

