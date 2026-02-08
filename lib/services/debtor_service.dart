import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/debtor_model.dart';
import '../models/debt_item_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

class DebtorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  /// Format amount with thousand separators
  String _formatAmount(double amount) {
    if (amount <= 0) return '0';
    final String amountStr = amount.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = amountStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(amountStr[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  CollectionReference get _debtorsCollection =>
      _firestore.collection('debtors');
  CollectionReference get _debtItemsCollection =>
      _firestore.collection('debt_items');

  // Check if debtor with same name exists
  Future<bool> debtorExists(String userId, String name) async {
    try {
      final normalizedName = name.trim().toLowerCase();
      final snapshot =
          await _debtorsCollection.where('userId', isEqualTo: userId).get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingName =
            (data['name'] ?? '').toString().trim().toLowerCase();
        if (existingName == normalizedName) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking debtor exists: $e');
      return false;
    }
  }

  // Get existing debtor by name
  Future<DebtorModel?> getDebtorByName(String userId, String name) async {
    try {
      final normalizedName = name.trim().toLowerCase();
      final snapshot =
          await _debtorsCollection.where('userId', isEqualTo: userId).get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingName =
            (data['name'] ?? '').toString().trim().toLowerCase();
        if (existingName == normalizedName) {
          return DebtorModel.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting debtor by name: $e');
      return null;
    }
  }

  // Add a new debtor (just name, no initial debt)
  Future<DebtorModel> addDebtor({
    required String userId,
    required String name,
    String product = '',
    double amount = 0,
    String? addedByUserName,
  }) async {
    final now = DateTime.now();

    try {
      // Check if debtor already exists
      final exists = await debtorExists(userId, name);
      if (exists) {
        throw Exception('DEBTOR_EXISTS');
      }

      final docRef = await _debtorsCollection.add({
        'userId': userId,
        'name': name,
        'product': product,
        'amount': amount,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': null,
        'itemCount': 0,
        'addedByUserName': addedByUserName,
      });

      return DebtorModel(
        id: docRef.id,
        userId: userId,
        name: name,
        product: product,
        amount: amount,
        createdAt: now,
        itemCount: 0,
        addedByUserName: addedByUserName,
      );
    } catch (e) {
      debugPrint('Error adding debtor: $e');
      rethrow;
    }
  }

  // Add a debt item to a debtor
  Future<DebtItemModel> addDebtItem({
    required String debtorId,
    required String userId,
    required String product,
    required double amount,
    required String debtorName,
    String? addedByUserName,
  }) async {
    final now = DateTime.now();

    try {
      // Add debt item with user info
      final docRef = await _debtItemsCollection.add({
        'debtorId': debtorId,
        'product': product,
        'amount': amount,
        'createdAt': Timestamp.fromDate(now),
        'addedByUserId': userId,
        'addedByUserName': addedByUserName ?? 'Unknown',
      });

      // Update debtor total amount
      await _updateDebtorTotal(debtorId);

      // Create transaction record
      await _transactionService.addTransaction(
        userId: userId,
        type: TransactionType.debt,
        amount: amount,
        referenceId: debtorId,
        description: '$product - $debtorName',
        performedByUserId: userId,
        performedByUserName: addedByUserName,
      );

      return DebtItemModel(
        id: docRef.id,
        debtorId: debtorId,
        product: product,
        amount: amount,
        createdAt: now,
        addedByUserId: userId,
        addedByUserName: addedByUserName ?? 'Unknown',
      );
    } catch (e) {
      debugPrint('Error adding debt item: $e');
      rethrow;
    }
  }

  // Update debtor total from debt items
  Future<void> _updateDebtorTotal(String debtorId) async {
    try {
      final items = await _debtItemsCollection
          .where('debtorId', isEqualTo: debtorId)
          .get();

      double total = 0;
      List<String> products = [];

      for (var doc in items.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
        products.add(data['product'] ?? '');
      }

      await _debtorsCollection.doc(debtorId).update({
        'amount': total,
        'product': products.join(', '),
        'itemCount': items.docs.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating debtor total: $e');
    }
  }

  // Update debt item amount
  Future<void> updateDebtItem({
    required String itemId,
    required String debtorId,
    required String userId,
    required String debtorName,
    required String product,
    required double oldAmount,
    required double newAmount,
    String? performedByUserName,
  }) async {
    try {
      await _debtItemsCollection.doc(itemId).update({
        'amount': newAmount,
      });
      await _updateDebtorTotal(debtorId);

      // Create edit transaction record
      await _transactionService.addTransaction(
        userId: userId,
        type: TransactionType.edit,
        amount: newAmount,
        referenceId: debtorId,
        description:
            '$product: IQD ${_formatAmount(oldAmount)} → IQD ${_formatAmount(newAmount)}',
        performedByUserId: userId,
        performedByUserName: performedByUserName,
      );
    } catch (e) {
      debugPrint('Error updating debt item: $e');
      rethrow;
    }
  }

  // Update debt item product name
  Future<void> updateDebtItemProduct({
    required String itemId,
    required String debtorId,
    required String userId,
    required String debtorName,
    required String oldProduct,
    required String newProduct,
    required double amount,
    String? performedByUserName,
  }) async {
    try {
      await _debtItemsCollection.doc(itemId).update({
        'product': newProduct,
      });
      await _updateDebtorTotal(debtorId);

      // Create edit transaction record for product name change
      await _transactionService.addTransaction(
        userId: userId,
        type: TransactionType.edit,
        amount: amount,
        referenceId: debtorId,
        description: 'Product renamed: $oldProduct → $newProduct',
        performedByUserId: userId,
        performedByUserName: performedByUserName,
      );
    } catch (e) {
      debugPrint('Error updating debt item product: $e');
      rethrow;
    }
  }

  // Delete a debt item without creating a payment transaction
  // Returns true if debtor was deleted (no more debts)
  Future<bool> deleteDebtItem({
    required String itemId,
    required String debtorId,
    required String userId,
    required String debtorName,
    required String product,
    required double amount,
  }) async {
    try {
      // Delete the debt item
      await _debtItemsCollection.doc(itemId).delete();

      // Check if there are any remaining debt items
      final remainingItems = await _debtItemsCollection
          .where('debtorId', isEqualTo: debtorId)
          .get();

      if (remainingItems.docs.isEmpty) {
        // No more debts, delete the debtor
        await _debtorsCollection.doc(debtorId).delete();
        debugPrint('Debtor $debtorName deleted - no more debts');
        return true; // Debtor was deleted
      } else {
        // Update debtor total
        await _updateDebtorTotal(debtorId);
        return false; // Debtor still has debts
      }
    } catch (e) {
      debugPrint('Error deleting debt item: $e');
      rethrow;
    }
  }

  // Settle (delete) a debt item
  // Returns true if debtor was deleted (no more debts)
  Future<bool> settleDebtItem({
    required String itemId,
    required String debtorId,
    required String userId,
    required String debtorName,
    required String product,
    required double amount,
    String? performedByUserName,
  }) async {
    try {
      // Delete the debt item
      await _debtItemsCollection.doc(itemId).delete();

      // Create payment transaction first (before potentially deleting debtor)
      await _transactionService.addTransaction(
        userId: userId,
        type: TransactionType.payment,
        amount: amount,
        referenceId: debtorId,
        description: 'Settled: $product - $debtorName',
        performedByUserId: userId,
        performedByUserName: performedByUserName,
      );

      // Check if there are any remaining debt items
      final remainingItems = await _debtItemsCollection
          .where('debtorId', isEqualTo: debtorId)
          .get();

      if (remainingItems.docs.isEmpty) {
        // No more debts, delete the debtor
        await _debtorsCollection.doc(debtorId).delete();
        debugPrint('Debtor $debtorName deleted - no more debts');
        return true; // Debtor was deleted
      } else {
        // Update debtor total
        await _updateDebtorTotal(debtorId);
        return false; // Debtor still has debts
      }
    } catch (e) {
      debugPrint('Error settling debt item: $e');
      rethrow;
    }
  }

  // Stream debt items for a debtor
  Stream<List<DebtItemModel>> streamDebtItems(String debtorId) {
    return _debtItemsCollection
        .where('debtorId', isEqualTo: debtorId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
            try {
              return DebtItemModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing debt item: $e');
              return null;
            }
          })
          .whereType<DebtItemModel>()
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    }).handleError((error) {
      debugPrint('Error streaming debt items: $error');
      return <DebtItemModel>[];
    });
  }

  // Update debtor name
  Future<void> updateDebtor({
    required String debtorId,
    String? name,
    String? product,
    double? amount,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updates['name'] = name;
      if (product != null) updates['product'] = product;
      if (amount != null) updates['amount'] = amount;

      await _debtorsCollection.doc(debtorId).update(updates);
    } catch (e) {
      debugPrint('Error updating debtor: $e');
      rethrow;
    }
  }

  // Settle payment (reduce debt amount) - legacy method
  Future<void> settlePayment({
    required String debtorId,
    required String userId,
    required double paymentAmount,
    required String debtorName,
    String? performedByUserName,
  }) async {
    try {
      final doc = await _debtorsCollection.doc(debtorId).get();
      if (!doc.exists) throw Exception('Debtor not found');

      final debtor = DebtorModel.fromFirestore(doc);
      final newAmount = debtor.amount - paymentAmount;

      await _debtorsCollection.doc(debtorId).update({
        'amount': newAmount < 0 ? 0 : newAmount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await _transactionService.addTransaction(
        userId: userId,
        type: TransactionType.payment,
        amount: paymentAmount,
        referenceId: debtorId,
        description: 'Payment from $debtorName',
        performedByUserId: userId,
        performedByUserName: performedByUserName,
      );
    } catch (e) {
      debugPrint('Error settling payment: $e');
      rethrow;
    }
  }

  // Delete debtor and all debt items
  Future<void> deleteDebtor(String debtorId) async {
    try {
      // Delete all debt items
      final items = await _debtItemsCollection
          .where('debtorId', isEqualTo: debtorId)
          .get();

      for (var doc in items.docs) {
        await doc.reference.delete();
      }

      // Delete debtor
      await _debtorsCollection.doc(debtorId).delete();
    } catch (e) {
      debugPrint('Error deleting debtor: $e');
      rethrow;
    }
  }

  // Stream all debtors for a user (sorted by amount - highest first)
  Stream<List<DebtorModel>> streamDebtors(String userId) {
    return _debtorsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      debugPrint(
          'Debtors snapshot received: ${snapshot.docs.length} documents');
      final debtors = snapshot.docs
          .map((doc) {
            try {
              return DebtorModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing debtor: $e');
              return null;
            }
          })
          .whereType<DebtorModel>()
          .toList();

      // Sort by amount (highest debt first)
      debtors.sort((a, b) => b.amount.compareTo(a.amount));
      return debtors;
    }).handleError((error) {
      debugPrint('Error streaming debtors: $error');
      return <DebtorModel>[];
    });
  }

  // Stream top debtors
  Stream<List<DebtorModel>> streamTopDebtors(String userId, {int limit = 3}) {
    return _debtorsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final debtors = snapshot.docs
          .map((doc) {
            try {
              return DebtorModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<DebtorModel>()
          .where((d) => d.amount > 0)
          .toList();

      debtors.sort((a, b) => b.amount.compareTo(a.amount));
      return debtors.take(limit).toList();
    }).handleError((error) {
      debugPrint('Error streaming top debtors: $error');
      return <DebtorModel>[];
    });
  }

  // Get total debtors count
  Stream<int> streamDebtorsCount(String userId) {
    return _debtorsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['amount'] ?? 0).toDouble() > 0;
      }).length;
    }).handleError((error) {
      debugPrint('Error streaming debtors count: $error');
      return 0;
    });
  }

  // Get total debt amount
  Stream<double> streamTotalDebt(String userId) {
    return _debtorsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }
      return total;
    }).handleError((error) {
      debugPrint('Error streaming total debt: $error');
      return 0.0;
    });
  }

  // Get last added debtor
  Stream<DebtorModel?> streamLastDebtor(String userId) {
    return _debtorsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final debtors = snapshot.docs
          .map((doc) {
            try {
              return DebtorModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<DebtorModel>()
          .where((d) => d.amount > 0)
          .toList();

      if (debtors.isEmpty) return null;

      debtors.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return debtors.first;
    }).handleError((error) {
      debugPrint('Error streaming last debtor: $error');
      return null;
    });
  }
}
