import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String barcodeId;
  final String userId;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.barcodeId,
    required this.userId,
    required this.createdAt,
  });

  /// Create ProductModel from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      barcodeId: data['barcodeId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ProductModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'barcodeId': barcodeId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? barcodeId,
    String? userId,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      barcodeId: barcodeId ?? this.barcodeId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, quantity: $quantity, barcodeId: $barcodeId)';
  }
}
