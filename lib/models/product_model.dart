import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/helpers.dart';

/// Produit stocké dans `products/{productId}`.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'BIF',
    required this.categoryId,
    required this.categoryName,
    required this.stock,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerWhatsapp,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final double price; // exprimé dans [currency]
  final String currency; // 'BIF', 'USD' ou 'EUR'
  final String categoryId;
  final String categoryName;
  final int stock;
  final String imageUrl; // URL Firebase Storage (ou data URL de secours)
  final String sellerId;
  final String sellerName;
  final String sellerWhatsapp;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isAvailable => stock > 0;

  /// Map envoyée à Firestore (l'id est celui du document, il n'est pas dupliqué).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'stock': stock,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerWhatsapp': sellerWhatsapp,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      price: parseDouble(map['price']),
      currency: (map['currency'] as String?) ?? 'BIF',
      categoryId: (map['categoryId'] as String?) ?? '',
      categoryName: (map['categoryName'] as String?) ?? '',
      stock: parseInt(map['stock']),
      imageUrl: (map['imageUrl'] as String?) ?? '',
      sellerId: (map['sellerId'] as String?) ?? '',
      sellerName: (map['sellerName'] as String?) ?? '',
      sellerWhatsapp: (map['sellerWhatsapp'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }
}
