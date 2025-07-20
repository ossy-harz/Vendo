import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String? icon;
  final int order;
  final String type; // 'product' or 'service'

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.order,
    required this.type,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'],
      order: data['order'] ?? 0,
      type: data['type'] ?? 'product',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'order': order,
      'type': type,
    };
  }
}

