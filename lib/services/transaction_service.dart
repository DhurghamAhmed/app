import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _transactionsCollection =>
      _firestore.collection('transactions');

  // Add a new transaction
  Future<TransactionModel> addTransaction({
    required String userId,
    required TransactionType type,
    required double amount,
    String? referenceId,
    String? description,
    String? performedByUserId,
    String? performedByUserName,
    bool shouldCleanup = false,
    int maxTransactions = 30,
  }) async {
    final now = DateTime.now();

    try {
      final docRef = await _transactionsCollection.add({
        'userId': userId,
        'type': _typeToString(type),
        'amount': amount,
        'referenceId': referenceId,
        'description': description,
        'date': Timestamp.fromDate(now),
        'performedByUserId': performedByUserId,
        'performedByUserName': performedByUserName,
      });

      debugPrint('Transaction added: ${docRef.id}');

      // Cleanup old transactions if enabled
      if (shouldCleanup) {
        // Run cleanup in background
        cleanupOldTransactions(userId, maxTransactions);
      }

      return TransactionModel(
        id: docRef.id,
        userId: userId,
        type: type,
        amount: amount,
        referenceId: referenceId,
        description: description,
        date: now,
        performedByUserId: performedByUserId,
        performedByUserName: performedByUserName,
      );
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  String _typeToString(TransactionType type) {
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

  // Stream all transactions (shared across all users)
  Stream<List<TransactionModel>> streamTransactions(String userId) {
    return _transactionsCollection.snapshots().map((snapshot) {
      debugPrint('Transactions snapshot: ${snapshot.docs.length} documents');
      final transactions = snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing transaction: $e');
              return null;
            }
          })
          .whereType<TransactionModel>()
          .toList();

      // Sort by date in memory
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    }).handleError((error) {
      debugPrint('Error streaming transactions: $error');
      return <TransactionModel>[];
    });
  }

  // Stream today's transactions (shared across all users)
  Stream<List<TransactionModel>> streamTodayTransactions(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _transactionsCollection.snapshots().map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing transaction: $e');
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((t) =>
              t.date.isAfter(startOfDay) || t.date.isAtSameMomentAs(startOfDay))
          .toList();

      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    }).handleError((error) {
      debugPrint('Error streaming today transactions: $error');
      return <TransactionModel>[];
    });
  }

  // Stream sales transactions only (shared across all users)
  Stream<List<TransactionModel>> streamSalesTransactions(String userId) {
    return _transactionsCollection.snapshots().map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing transaction: $e');
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((t) => t.type == TransactionType.sale)
          .toList();

      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    }).handleError((error) {
      debugPrint('Error streaming sales transactions: $error');
      return <TransactionModel>[];
    });
  }

  // Stream debtor transactions (debt + payment + edit) (shared across all users)
  Stream<List<TransactionModel>> streamDebtorTransactions(String userId) {
    return _transactionsCollection.snapshots().map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing transaction: $e');
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((t) =>
              t.type == TransactionType.debt ||
              t.type == TransactionType.payment ||
              t.type == TransactionType.edit)
          .toList();

      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    }).handleError((error) {
      debugPrint('Error streaming debtor transactions: $error');
      return <TransactionModel>[];
    });
  }

  // Get today's sales count (shared across all users)
  Stream<int> streamTodaySalesCount(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _transactionsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((t) =>
              t.type == TransactionType.sale &&
              (t.date.isAfter(startOfDay) ||
                  t.date.isAtSameMomentAs(startOfDay)))
          .length;
    }).handleError((error) {
      debugPrint('Error streaming today sales count: $error');
      return 0;
    });
  }

  // Get today's sales total (shared across all users)
  Stream<double> streamTodaySalesTotal(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _transactionsCollection.snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        try {
          final tx = TransactionModel.fromFirestore(doc);
          if (tx.type == TransactionType.sale &&
              (tx.date.isAfter(startOfDay) ||
                  tx.date.isAtSameMomentAs(startOfDay))) {
            total += tx.amount;
          }
        } catch (e) {
          debugPrint('Error parsing transaction for total: $e');
        }
      }
      return total;
    }).handleError((error) {
      debugPrint('Error streaming today sales total: $error');
      return 0.0;
    });
  }

  // Delete all sales transactions for a specific list
  Future<void> deleteSalesTransactionsForList(
      String userId, String listId) async {
    try {
      final snapshot = await _transactionsCollection.get();

      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        try {
          final tx = TransactionModel.fromFirestore(doc);
          if (tx.type == TransactionType.sale && tx.referenceId == listId) {
            batch.delete(doc.reference);
            count++;
          }
        } catch (e) {
          debugPrint('Error checking transaction for deletion: $e');
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint('Deleted $count sales transactions for list: $listId');
      }
    } catch (e) {
      debugPrint('Error deleting sales transactions for list: $e');
    }
  }

  // Delete all sales transactions for closed lists (cleanup old daily sales)
  Future<void> deleteOldSalesTransactions(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await _transactionsCollection.get();

      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        try {
          final tx = TransactionModel.fromFirestore(doc);
          // Delete sales transactions from before today
          if (tx.type == TransactionType.sale && tx.date.isBefore(startOfDay)) {
            batch.delete(doc.reference);
            count++;
          }
        } catch (e) {
          debugPrint('Error checking transaction for deletion: $e');
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint('Deleted $count old sales transactions');
      }
    } catch (e) {
      debugPrint('Error deleting old sales transactions: $e');
    }
  }

  // Get today's payments total (shared across all users)
  Stream<double> streamTodayPaymentsTotal(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _transactionsCollection.snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        try {
          final tx = TransactionModel.fromFirestore(doc);
          if (tx.type == TransactionType.payment &&
              (tx.date.isAfter(startOfDay) ||
                  tx.date.isAtSameMomentAs(startOfDay))) {
            total += tx.amount;
          }
        } catch (e) {
          debugPrint('Error parsing transaction for payment total: $e');
        }
      }
      return total;
    }).handleError((error) {
      debugPrint('Error streaming today payments total: $error');
      return 0.0;
    });
  }

  // Get monthly sales total (shared across all users)
  Stream<double> streamMonthlySalesTotal(String userId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _transactionsCollection.snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        try {
          final tx = TransactionModel.fromFirestore(doc);
          if (tx.type == TransactionType.sale &&
              (tx.date.isAfter(startOfMonth) ||
                  tx.date.isAtSameMomentAs(startOfMonth))) {
            total += tx.amount;
          }
        } catch (e) {
          debugPrint('Error parsing transaction for monthly total: $e');
        }
      }
      return total;
    }).handleError((error) {
      debugPrint('Error streaming monthly sales total: $error');
      return 0.0;
    });
  }

  // Get today's transactions count (shared across all users)
  Stream<int> streamTodayTransactionsCount(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _transactionsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((t) =>
              t.type == TransactionType.sale &&
              (t.date.isAfter(startOfDay) ||
                  t.date.isAtSameMomentAs(startOfDay)))
          .length;
    }).handleError((error) {
      debugPrint('Error streaming today transactions count: $error');
      return 0;
    });
  }

  // Get last sale (shared across all users)
  Stream<Map<String, dynamic>?> streamLastSale(String userId) {
    return _transactionsCollection.snapshots().map((snapshot) {
      final sales = snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((t) => t.type == TransactionType.sale)
          .toList();

      if (sales.isEmpty) return null;

      sales.sort((a, b) => b.date.compareTo(a.date));
      final lastSale = sales.first;

      return {
        'amount': lastSale.amount,
        'date': lastSale.date,
        'description': lastSale.description,
      };
    }).handleError((error) {
      debugPrint('Error streaming last sale: $error');
      return null;
    });
  }

  // Clean up old transactions if limit is enabled (shared across all users)
  Future<void> cleanupOldTransactions(String userId, int maxCount) async {
    try {
      final snapshot = await _transactionsCollection.get();

      if (snapshot.docs.length <= maxCount) {
        debugPrint(
            'No cleanup needed. Current: ${snapshot.docs.length}, Max: $maxCount');
        return;
      }

      // Sort by date (newest first)
      final transactions = snapshot.docs
          .map((doc) {
            try {
              return {
                'doc': doc,
                'date':
                    (doc.data() as Map<String, dynamic>)['date'] as Timestamp?,
              };
            } catch (e) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      transactions.sort((a, b) {
        final dateA = a['date'] as Timestamp?;
        final dateB = b['date'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      // Delete transactions beyond the limit
      final toDelete = transactions.skip(maxCount).toList();

      if (toDelete.isEmpty) return;

      final batch = _firestore.batch();
      for (var item in toDelete) {
        final doc = item['doc'] as DocumentSnapshot;
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${toDelete.length} old transactions');
    } catch (e) {
      debugPrint('Error cleaning up old transactions: $e');
    }
  }

  // Get transactions for a specific debtor (includes debt, payment, and edit transactions)
  Stream<List<TransactionModel>> streamDebtorHistory(
    String userId,
    String debtorId,
  ) {
    debugPrint(
        'Streaming debtor history for debtorId: $debtorId (shared across all users)');

    // Filter by referenceId in memory to avoid composite index requirement
    return _transactionsCollection.snapshots().map((snapshot) {
      debugPrint('Total transactions: ${snapshot.docs.length}');

      final transactions = snapshot.docs
          .map((doc) {
            try {
              final tx = TransactionModel.fromFirestore(doc);
              return tx;
            } catch (e) {
              debugPrint('Error parsing transaction: $e');
              return null;
            }
          })
          .whereType<TransactionModel>()
          .where((tx) =>
              tx.referenceId == debtorId) // Filter by debtorId in memory
          .toList();

      debugPrint(
          'Filtered transactions for debtorId $debtorId: ${transactions.length}');

      // Log each transaction for debugging
      for (var tx in transactions) {
        debugPrint(
            'Transaction: type=${tx.type}, amount=${tx.amount}, desc=${tx.description}, refId=${tx.referenceId}');
      }

      // Sort by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    }).handleError((error) {
      debugPrint('Error streaming debtor history: $error');
      return <TransactionModel>[];
    });
  }
}
