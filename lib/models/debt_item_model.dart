import 'package:cloud_firestore/cloud_firestore.dart';

class DebtItemModel {
  final String id;
  final String debtorId;
  final String product;
  final double amount;
  final DateTime createdAt;
  final String? addedByUserId;
  final String? addedByUserName;

  DebtItemModel({
    required this.id,
    required this.debtorId,
    required this.product,
    required this.amount,
    required this.createdAt,
    this.addedByUserId,
    this.addedByUserName,
  });

  factory DebtItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DebtItemModel(
      id: doc.id,
      debtorId: data['debtorId'] ?? '',
      product: data['product'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedByUserId: data['addedByUserId'],
      addedByUserName: data['addedByUserName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'debtorId': debtorId,
      'product': product,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'addedByUserId': addedByUserId,
      'addedByUserName': addedByUserName,
    };
  }
}
