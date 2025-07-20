import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String type; // product or service
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.order,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      type: data['type'] ?? 'product',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'type': type,
      'order': order,
    };
  }
}

class CategoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';
  
  // Get all categories
  Stream<List<Category>> getCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }
  
  // Get product categories
  Stream<List<Category>> getProductCategories() {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'product')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }
  
  // Get service categories
  Stream<List<Category>> getServiceCategories() {
    return _firestore
        .collection(_collection)
        .where('type', isEqualTo: 'service')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }
  
  // Get category by id
  Future<Category?> getCategoryById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Category.fromFirestore(doc);
    }
    return null;
  }
  
  // Create category
  Future<String> createCategory(Category category) async {
    // Create a new document reference
    final docRef = _firestore.collection(_collection).doc();
    
    // Save to Firestore
    await docRef.set(category.toFirestore());
    
    // Return the new category ID
    return docRef.id;
  }
  
  // Update category
  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toFirestore());
    
    notifyListeners();
  }
  
  // Delete category
  Future<void> deleteCategory(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    
    notifyListeners();
  }
  
  // Get default categories
  List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'electronics',
        name: 'Electronics',
        icon: 'devices',
        type: 'product',
        order: 1,
      ),
      Category(
        id: 'furniture',
        name: 'Furniture',
        icon: 'chair',
        type: 'product',
        order: 2,
      ),
      Category(
        id: 'clothing',
        name: 'Clothing',
        icon: 'checkroom',
        type: 'product',
        order: 3,
      ),
      Category(
        id: 'vehicles',
        name: 'Vehicles',
        icon: 'directions_car',
        type: 'product',
        order: 4,
      ),
      Category(
        id: 'home_garden',
        name: 'Home & Garden',
        icon: 'yard',
        type: 'product',
        order: 5,
      ),
      Category(
        id: 'cleaning',
        name: 'Cleaning',
        icon: 'cleaning_services',
        type: 'service',
        order: 1,
      ),
      Category(
        id: 'repair',
        name: 'Repair',
        icon: 'handyman',
        type: 'service',
        order: 2,
      ),
      Category(
        id: 'tutoring',
        name: 'Tutoring',
        icon: 'school',
        type: 'service',
        order: 3,
      ),
      Category(
        id: 'beauty',
        name: 'Beauty & Wellness',
        icon: 'spa',
        type: 'service',
        order: 4,
      ),
      Category(
        id: 'transportation',
        name: 'Transportation',
        icon: 'local_taxi',
        type: 'service',
        order: 5,
      ),
    ];
  }
}

