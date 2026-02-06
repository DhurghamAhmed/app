import 'package:cloud_firestore/cloud_firestore.dart';

class SalesListModel {
  final String id;
  final String userId;
  final bool isOpen;
  final DateTime dateOpened;
  final DateTime? dateClosed;
  final double totalAmount;

  SalesListModel({
    required this.id,
    required this.userId,
    required this.isOpen,
    required this.dateOpened,
    this.dateClosed,
    this.totalAmount = 0,
  });

  factory SalesListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesListModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      isOpen: data['isOpen'] ?? false,
      dateOpened: (data['dateOpened'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateClosed: (data['dateClosed'] as Timestamp?)?.toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'isOpen': isOpen,
      'dateOpened': Timestamp.fromDate(dateOpened),
      'dateClosed': dateClosed != null ? Timestamp.fromDate(dateClosed!) : null,
      'totalAmount': totalAmount,
    };
  }

  SalesListModel copyWith({
    String? id,
    String? userId,
    bool? isOpen,
    DateTime? dateOpened,
    DateTime? dateClosed,
    double? totalAmount,
  }) {
    return SalesListModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isOpen: isOpen ?? this.isOpen,
      dateOpened: dateOpened ?? this.dateOpened,
      dateClosed: dateClosed ?? this.dateClosed,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

class SalesItemModel {
  final String id;
  final String listId;
  final String name;
  final double price;
  final int quantity;
  final DateTime createdAt;

  SalesItemModel({
    required this.id,
    required this.listId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.createdAt,
  });

  double get total => price * quantity;

  factory SalesItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesItemModel(
      id: doc.id,
      listId: data['listId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SalesItemModel copyWith({
    String? id,
    String? listId,
    String? name,
    double? price,
    int? quantity,
    DateTime? createdAt,
  }) {
    return SalesItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
