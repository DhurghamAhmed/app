import 'package:cloud_firestore/cloud_firestore.dart';

class DebtorModel {
  final String id;
  final String userId;
  final String name;
  final String product;
  final double amount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  final String? addedByUserName;

  DebtorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.product,
    required this.amount,
    required this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
    this.addedByUserName,
  });

  factory DebtorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DebtorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      product: data['product'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      itemCount: (data['itemCount'] ?? 0).toInt(),
      addedByUserName: data['addedByUserName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'product': product,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'itemCount': itemCount,
      'addedByUserName': addedByUserName,
    };
  }

  DebtorModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? product,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
    String? addedByUserName,
  }) {
    return DebtorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      product: product ?? this.product,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
      addedByUserName: addedByUserName ?? this.addedByUserName,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}
