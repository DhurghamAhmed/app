import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { sale, debt, payment, edit }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String? referenceId;
  final String? description;
  final DateTime date;
  final String? performedByUserId;
  final String? performedByUserName;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.referenceId,
    this.description,
    required this.date,
    this.performedByUserId,
    this.performedByUserName,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseTransactionType(data['type']),
      amount: (data['amount'] ?? 0).toDouble(),
      referenceId: data['referenceId'],
      description: data['description'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      performedByUserId: data['performedByUserId'],
      performedByUserName: data['performedByUserName'],
    );
  }

  static TransactionType _parseTransactionType(String? type) {
    switch (type) {
      case 'sale':
        return TransactionType.sale;
      case 'debt':
        return TransactionType.debt;
      case 'payment':
        return TransactionType.payment;
      case 'edit':
        return TransactionType.edit;
      default:
        return TransactionType.sale;
    }
  }

  String get typeString {
    switch (type) {
      case TransactionType.sale:
        return 'sale';
      case TransactionType.debt:
        return 'debt';
      case TransactionType.payment:
        return 'payment';
      case TransactionType.edit:
        return 'edit';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.sale:
        return 'Sale';
      case TransactionType.debt:
        return 'New Debt';
      case TransactionType.payment:
        return 'Payment Received';
      case TransactionType.edit:
        return 'Price Updated';
    }
  }

  bool get isPositive =>
      type == TransactionType.sale || type == TransactionType.payment;
  bool get isEdit => type == TransactionType.edit;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': typeString,
      'amount': amount,
      'referenceId': referenceId,
      'description': description,
      'date': Timestamp.fromDate(date),
      'performedByUserId': performedByUserId,
      'performedByUserName': performedByUserName,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? referenceId,
    String? description,
    DateTime? date,
    String? performedByUserId,
    String? performedByUserName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      date: date ?? this.date,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      performedByUserName: performedByUserName ?? this.performedByUserName,
    );
  }
}
