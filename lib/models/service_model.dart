import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final double price;
  final String priceType; // hourly, fixed, etc.
  final String category;
  final List<String> images;
  final String location;
  final GeoPoint? coordinates;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final List<String> tags;
  final bool isFeatured;
  final List<String> workHistory;
  final List<String> testimonials;

  Service({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.price,
    required this.priceType,
    required this.category,
    required this.images,
    required this.location,
    this.coordinates,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    required this.viewCount,
    required this.tags,
    required this.isFeatured,
    required this.workHistory,
    required this.testimonials,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      priceType: data['priceType'] ?? 'hourly',
      category: data['category'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      location: data['location'] ?? '',
      coordinates: data['coordinates'],
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['viewCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
      workHistory: List<String>.from(data['workHistory'] ?? []),
      testimonials: List<String>.from(data['testimonials'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'title': title,
      'description': description,
      'price': price,
      'priceType': priceType,
      'category': category,
      'images': images,
      'location': location,
      'coordinates': coordinates,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'viewCount': viewCount,
      'tags': tags,
      'isFeatured': isFeatured,
      'workHistory': workHistory,
      'testimonials': testimonials,
    };
  }

  Service copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    double? price,
    String? priceType,
    String? category,
    List<String>? images,
    String? location,
    GeoPoint? coordinates,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    List<String>? tags,
    bool? isFeatured,
    List<String>? workHistory,
    List<String>? testimonials,
  }) {
    return Service(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      category: category ?? this.category,
      images: images ?? this.images,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      workHistory: workHistory ?? this.workHistory,
      testimonials: testimonials ?? this.testimonials,
    );
  }
}

