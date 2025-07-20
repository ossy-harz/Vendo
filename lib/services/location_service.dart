import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can get the location
    return await Geolocator.getCurrentPosition();
  }
  
  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.locality}, ${place.administrativeArea}';
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown location';
    }
  }
  
  // Get coordinates from address
  Future<GeoPoint?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return GeoPoint(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }
  
  // Calculate distance between two coordinates
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  
  // Find nearby products
  Future<List<Map<String, dynamic>>> findNearbyProducts(GeoPoint userLocation, double radiusInKm) async {
    try {
      // Get all products
      final productsQuery = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final List<Map<String, dynamic>> nearbyProducts = [];
      
      for (final doc in productsQuery.docs) {
        final data = doc.data();
        final GeoPoint? productLocation = data['coordinates'];
        
        if (productLocation != null) {
          // Calculate distance
          final double distanceInMeters = calculateDistance(userLocation, productLocation);
          final double distanceInKm = distanceInMeters / 1000;
          
          if (distanceInKm <= radiusInKm) {
            nearbyProducts.add({
              'id': doc.id,
              'data': data,
              'distance': distanceInKm,
            });
          }
        }
      }
      
      // Sort by distance
      nearbyProducts.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      return nearbyProducts;
    } catch (e) {
      print('Error finding nearby products: $e');
      return [];
    }
  }
  
  // Find nearby services
  Future<List<Map<String, dynamic>>> findNearbyServices(GeoPoint userLocation, double radiusInKm) async {
    try {
      // Get all services
      final servicesQuery = await _firestore
          .collection('services')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final List<Map<String, dynamic>> nearbyServices = [];
      
      for (final doc in servicesQuery.docs) {
        final data = doc.data();
        final GeoPoint? serviceLocation = data['coordinates'];
        
        if (serviceLocation != null) {
          // Calculate distance
          final double distanceInMeters = calculateDistance(userLocation, serviceLocation);
          final double distanceInKm = distanceInMeters / 1000;
          
          if (distanceInKm <= radiusInKm) {
            nearbyServices.add({
              'id': doc.id,
              'data': data,
              'distance': distanceInKm,
            });
          }
        }
      }
      
      // Sort by distance
      nearbyServices.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      return nearbyServices;
    } catch (e) {
      print('Error finding nearby services: $e');
      return [];
    }
  }
  
  // Update user location
  Future<void> updateUserLocation(String userId, GeoPoint location) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'location': location,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user location: $e');
    }
  }
}

