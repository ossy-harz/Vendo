import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> images;
  final String location;
  final GeoPoint? coordinates;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final List<String> tags;
  final bool isFeatured;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    required this.location,
    this.coordinates,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    required this.viewCount,
    required this.tags,
    required this.isFeatured,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      location: data['location'] ?? '',
      coordinates: data['coordinates'],
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['viewCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'images': images,
      'location': location,
      'coordinates': coordinates,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'viewCount': viewCount,
      'tags': tags,
      'isFeatured': isFeatured,
    };
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? images,
    String? location,
    GeoPoint? coordinates,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    List<String>? tags,
    bool? isFeatured,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

