import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/service_model.dart';

class ServiceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'services';
  
  // Get all services
  Stream<List<Service>> getServices() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }
  
  // Get featured services
  Stream<List<Service>> getFeaturedServices() {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }
  
  // Get services by category
  Stream<List<Service>> getServicesByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }
  
  // Get services by provider
  Stream<List<Service>> getServicesByProvider(String providerId) {
    return _firestore
        .collection(_collection)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }
  
  // Get service by id
  Future<Service?> getServiceById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Service.fromFirestore(doc);
    }
    return null;
  }
  
  // Create service
  Future<String> createService(Service service, List<File> imageFiles) async {
    // Create a new document reference
    final docRef = _firestore.collection(_collection).doc();
    
    // Upload images
    final List<String> imageUrls = await _uploadImages(imageFiles, docRef.id);
    
    // Create service with images and new ID
    final newService = service.copyWith(
      id: docRef.id,
      images: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Save to Firestore
    await docRef.set(newService.toFirestore());
    
    // Return the new service ID
    return docRef.id;
  }
  
  // Update service
  Future<void> updateService(Service service, List<File>? newImageFiles) async {
    List<String> imageUrls = service.images;
    
    // Upload new images if provided
    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      final newUrls = await _uploadImages(newImageFiles, service.id);
      imageUrls = [...imageUrls, ...newUrls];
    }
    
    // Update service with new images
    final updatedService = service.copyWith(
      images: imageUrls,
      updatedAt: DateTime.now(),
    );
    
    // Update in Firestore
    await _firestore
        .collection(_collection)
        .doc(service.id)
        .update(updatedService.toFirestore());
    
    notifyListeners();
  }
  
  // Delete service
  Future<void> deleteService(String id) async {
    // Get the service to access its images
    final service = await getServiceById(id);
    
    // Delete the service document
    await _firestore.collection(_collection).doc(id).delete();
    
    // Delete associated images
    if (service != null) {
      for (final imageUrl in service.images) {
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
  
  // Mark service as unavailable
  Future<void> markServiceAsUnavailable(String id) async {
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
  
  // Add work history
  Future<void> addWorkHistory(String serviceId, String workHistory) async {
    await _firestore.collection(_collection).doc(serviceId).update({
      'workHistory': FieldValue.arrayUnion([workHistory]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    notifyListeners();
  }
  
  // Add testimonial
  Future<void> addTestimonial(String serviceId, String testimonial) async {
    await _firestore.collection(_collection).doc(serviceId).update({
      'testimonials': FieldValue.arrayUnion([testimonial]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    notifyListeners();
  }
  
  // Search services
  Future<List<Service>> searchServices(String query) async {
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
    final Map<String, Service> uniqueServices = {};
    
    for (final doc in titleResults.docs) {
      uniqueServices[doc.id] = Service.fromFirestore(doc);
    }
    
    for (final doc in descriptionResults.docs) {
      uniqueServices[doc.id] = Service.fromFirestore(doc);
    }
    
    for (final doc in tagResults.docs) {
      uniqueServices[doc.id] = Service.fromFirestore(doc);
    }
    
    return uniqueServices.values.toList();
  }
  
  // Helper method to upload images
  Future<List<String>> _uploadImages(List<File> images, String serviceId) async {
    final List<String> imageUrls = [];
    
    for (final image in images) {
      final uuid = const Uuid().v4();
      final path = 'services/$serviceId/$uuid.jpg';
      final ref = _storage.ref().child(path);
      
      // Upload image
      await ref.putFile(image);
      
      // Get download URL
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    return imageUrls;
  }
  
  // Remove image from service
  Future<void> removeImage(String serviceId, String imageUrl) async {
    // Get the current service
    final service = await getServiceById(serviceId);
    if (service == null) return;
    
    // Remove the image URL from the service
    final updatedImages = List<String>.from(service.images)
      ..remove(imageUrl);
    
    // Update the service
    await _firestore.collection(_collection).doc(serviceId).update({
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

