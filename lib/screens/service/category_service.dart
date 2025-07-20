import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../utils/constants.dart';

class CategoryService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Category> _productCategories = [];
  List<Category> _serviceCategories = [];

  // Get product categories
  Future<void> fetchProductCategories() async {
    if (_productCategories.isNotEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('type', isEqualTo: 'product')
          .orderBy('order')
          .get();
      _productCategories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching product categories: $e');
    }
  }

  List<Category> getProductCategories() => _productCategories;

  // Get service categories
  Future<void> fetchServiceCategories() async {
    if (_serviceCategories.isNotEmpty) return;
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('type', isEqualTo: 'service')
          .orderBy('order')
          .get();
      _serviceCategories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching service categories: $e');
    }
  }

  List<Category> getServiceCategories() => _serviceCategories;

  // Create initial categories if they don't exist
  Future<void> ensureCategoriesExist() async {
    final snapshot = await _firestore.collection('categories').limit(1).get();
    if (snapshot.docs.isEmpty) {
      for (int i = 0; i < AppConstants.productCategories.length; i++) {
        await _firestore.collection('categories').add({
          'name': AppConstants.productCategories[i],
          'order': i,
          'type': 'product',
        });
      }
      for (int i = 0; i < AppConstants.serviceCategories.length; i++) {
        await _firestore.collection('categories').add({
          'name': AppConstants.serviceCategories[i],
          'order': i,
          'type': 'service',
        });
      }
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      return doc.exists ? Category.fromFirestore(doc) : null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }
}
