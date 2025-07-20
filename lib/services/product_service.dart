import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'products';
  
  // Get all products
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
  
  // Get featured products
  Stream<List<Product>> getFeaturedProducts() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
  
  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
  
  // Get products by seller
  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _firestore
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
  
  // Get product by id
  Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Product.fromFirestore(doc);
    }
    return null;
  }
  
  // Create product
  Future<String> createProduct(Product product, List<File> imageFiles) async {
    // Create a new document reference
    final docRef = _firestore.collection(_collection).doc();
    
    // Upload images
    final List<String> imageUrls = await _uploadImages(imageFiles, docRef.id);
    
    // Create product with images and new ID
    final newProduct = product.copyWith(
      id: docRef.id,
      images: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Save to Firestore
    await docRef.set(newProduct.toFirestore());
    
    // Return the new product ID
    return docRef.id;
  }
  
  // Update product
  Future<void> updateProduct(Product product, List<File>? newImageFiles) async {
    List<String> imageUrls = product.images;
    
    // Upload new images if provided
    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      final newUrls = await _uploadImages(newImageFiles, product.id);
      imageUrls = [...imageUrls, ...newUrls];
    }
    
    // Update product with new images
    final updatedProduct = product.copyWith(
      images: imageUrls,
      updatedAt: DateTime.now(),
    );
    
    // Update in Firestore
    await _firestore
        .collection(_collection)
        .doc(product.id)
        .update(updatedProduct.toFirestore());
    
    notifyListeners();
  }
  
  // Delete product
  Future<void> deleteProduct(String id) async {
    // Get the product to access its images
    final product = await getProductById(id);
    
    // Delete the product document
    await _firestore.collection(_collection).doc(id).delete();
    
    // Delete associated images
    if (product != null) {
      for (final imageUrl in product.images) {
        try {
          // Extract the path from the URL
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }
    
    notifyListeners();
  }
  
  // Mark product as sold
  Future<void> markProductAsSold(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'isAvailable': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    notifyListeners();
  }
  
  // Increment view count
  Future<void> incrementViewCount(String id) async {
    await _firestore.collection(_collection).doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }
  
  // Search products
  Future<List<Product>> searchProducts(String query) async {
    // Convert query to lowercase for case-insensitive search
    query = query.toLowerCase();
    
    // Search in title, description, and tags
    final titleResults = await _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();
    
    // We can't do multiple range queries in a single Firestore query,
    // so we need to do separate queries and combine the results
    final descriptionResults = await _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('description')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .get();
    
    // For tags, we need to use array-contains
    final tagResults = await _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .where('tags', arrayContains: query)
        .get();
    
    // Combine results and remove duplicates
    final Map<String, Product> uniqueProducts = {};
    
    for (final doc in titleResults.docs) {
      uniqueProducts[doc.id] = Product.fromFirestore(doc);
    }
    
    for (final doc in descriptionResults.docs) {
      uniqueProducts[doc.id] = Product.fromFirestore(doc);
    }
    
    for (final doc in tagResults.docs) {
      uniqueProducts[doc.id] = Product.fromFirestore(doc);
    }
    
    return uniqueProducts.values.toList();
  }
  
  // Helper method to upload images
  Future<List<String>> _uploadImages(List<File> images, String productId) async {
    final List<String> imageUrls = [];
    
    for (final image in images) {
      final uuid = const Uuid().v4();
      final path = 'products/$productId/$uuid.jpg';
      final ref = _storage.ref().child(path);
      
      // Upload image
      await ref.putFile(image);
      
      // Get download URL
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    return imageUrls;
  }
  
  // Remove image from product
  Future<void> removeImage(String productId, String imageUrl) async {
    // Get the current product
    final product = await getProductById(productId);
    if (product == null) return;
    
    // Remove the image URL from the product
    final updatedImages = List<String>.from(product.images)
      ..remove(imageUrl);
    
    // Update the product
    await _firestore.collection(_collection).doc(productId).update({
      'images': updatedImages,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Delete the image from storage
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
    
    notifyListeners();
  }
}

