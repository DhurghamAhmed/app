import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sales_list_model.dart';
import '../models/transaction_model.dart';
import 'transaction_service.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  // Collection references
  CollectionReference get _salesListsCollection =>
      _firestore.collection('sales_lists');
  CollectionReference get _salesItemsCollection =>
      _firestore.collection('sales_items');
  CollectionReference get _monthlySalesCollection =>
      _firestore.collection('monthly_sales');

  // Create a new sales list (only if no open list exists) - shared across all users
  Future<SalesListModel?> openNewSalesList(String userId) async {
    try {
      // Check if there's already an open list (shared across all users)
      final existingOpen =
          await _salesListsCollection.where('isOpen', isEqualTo: true).get();

      if (existingOpen.docs.isNotEmpty) {
        // Return existing open list
        return SalesListModel.fromFirestore(existingOpen.docs.first);
      }

      // Create new list
      final now = DateTime.now();
      final docRef = await _salesListsCollection.add({
        'userId': userId,
        'isOpen': true,
        'dateOpened': Timestamp.fromDate(now),
        'dateClosed': null,
        'totalAmount': 0,
      });

      debugPrint('New sales list created: ${docRef.id}');

      return SalesListModel(
        id: docRef.id,
        userId: userId,
        isOpen: true,
        dateOpened: now,
        totalAmount: 0,
      );
    } catch (e) {
      debugPrint('Error opening new sales list: $e');
      rethrow;
    }
  }

  // Close a sales list
  Future<void> closeSalesList(String listId, {String? userId}) async {
    try {
      // Get list total before closing
      final listDoc = await _salesListsCollection.doc(listId).get();
      final listData = listDoc.data() as Map<String, dynamic>?;
      final listTotal = (listData?['totalAmount'] ?? 0).toDouble();
      final listUserId = userId ?? listData?['userId'] as String?;

      // Close the list
      await _salesListsCollection.doc(listId).update({
        'isOpen': false,
        'dateClosed': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('Sales list closed: $listId');

      // Add to monthly sales if list has items
      if (listUserId != null && listTotal > 0) {
        await _addToMonthlySales(listUserId, listTotal);
        debugPrint('Added $listTotal to monthly sales');
      }

      // Delete sales transactions for this closed list (reset Daily Sales)
      if (listUserId != null) {
        await _transactionService.deleteSalesTransactionsForList(
            listUserId, listId);
        debugPrint('Sales transactions deleted for list: $listId');

        // Run cleanup in background
        cleanupOldSalesLists(listUserId);
      }
    } catch (e) {
      debugPrint('Error closing sales list: $e');
      rethrow;
    }
  }

  // Add amount to monthly sales
  Future<void> _addToMonthlySales(String userId, double amount) async {
    try {
      final now = DateTime.now();
      final monthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}'; // e.g., "2025-01"
      final docId = '${userId}_$monthKey';

      final docRef = _monthlySalesCollection.doc(docId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing month
        await docRef.update({
          'totalAmount': FieldValue.increment(amount),
          'lastUpdated': Timestamp.fromDate(now),
          'closedListsCount': FieldValue.increment(1),
        });
      } else {
        // Create new month record
        await docRef.set({
          'userId': userId,
          'year': now.year,
          'month': now.month,
          'monthKey': monthKey,
          'totalAmount': amount,
          'createdAt': Timestamp.fromDate(now),
          'lastUpdated': Timestamp.fromDate(now),
          'closedListsCount': 1,
        });
      }
    } catch (e) {
      debugPrint('Error adding to monthly sales: $e');
      // Don't rethrow - this is a secondary operation
    }
  }

  // Add item to sales list
  Future<SalesItemModel> addSalesItem({
    required String listId,
    required String userId,
    required String name,
    required double price,
    int quantity = 1,
  }) async {
    try {
      final now = DateTime.now();

      final docRef = await _salesItemsCollection.add({
        'listId': listId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'createdAt': Timestamp.fromDate(now),
      });

      final itemTotal = price * quantity;

      // Update list total
      await _updateListTotal(listId, itemTotal);

      // Create a transaction record for the sale
      await _transactionService.addTransaction(
        userId: userId,
        type: TransactionType.sale,
        amount: itemTotal,
        referenceId: listId,
        description: '$name x$quantity',
      );

      debugPrint('Sales item added: ${docRef.id}');

      return SalesItemModel(
        id: docRef.id,
        listId: listId,
        name: name,
        price: price,
        quantity: quantity,
        createdAt: now,
      );
    } catch (e) {
      debugPrint('Error adding sales item: $e');
      rethrow;
    }
  }

  // Update list total
  Future<void> _updateListTotal(String listId, double addAmount) async {
    try {
      final doc = await _salesListsCollection.doc(listId).get();
      if (doc.exists) {
        final currentTotal =
            (doc.data() as Map<String, dynamic>)['totalAmount'] ?? 0;
        await _salesListsCollection.doc(listId).update({
          'totalAmount': currentTotal + addAmount,
        });
      }
    } catch (e) {
      debugPrint('Error updating list total: $e');
    }
  }

  // Remove item from sales list
  Future<void> removeSalesItem(String itemId, String listId) async {
    try {
      // Get item to calculate total reduction
      final itemDoc = await _salesItemsCollection.doc(itemId).get();
      if (itemDoc.exists) {
        final item = SalesItemModel.fromFirestore(itemDoc);

        // Delete item
        await _salesItemsCollection.doc(itemId).delete();

        // Update list total (subtract)
        await _updateListTotal(listId, -item.total);

        debugPrint('Sales item removed: $itemId');
      }
    } catch (e) {
      debugPrint('Error removing sales item: $e');
      rethrow;
    }
  }

  // Update sales item
  Future<void> updateSalesItem({
    required String itemId,
    required String listId,
    String? name,
    double? price,
    int? quantity,
  }) async {
    try {
      // Get current item
      final itemDoc = await _salesItemsCollection.doc(itemId).get();
      if (!itemDoc.exists) return;

      final currentItem = SalesItemModel.fromFirestore(itemDoc);
      final oldTotal = currentItem.total;

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (quantity != null) updates['quantity'] = quantity;

      await _salesItemsCollection.doc(itemId).update(updates);

      // Calculate new total and update list
      final newPrice = price ?? currentItem.price;
      final newQuantity = quantity ?? currentItem.quantity;
      final newTotal = newPrice * newQuantity;
      final difference = newTotal - oldTotal;

      if (difference != 0) {
        await _updateListTotal(listId, difference);
      }

      debugPrint('Sales item updated: $itemId');
    } catch (e) {
      debugPrint('Error updating sales item: $e');
      rethrow;
    }
  }

  // Get current open list (shared across all users)
  Stream<SalesListModel?> streamOpenList(String userId) {
    return _salesListsCollection
        .where('isOpen', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      try {
        return SalesListModel.fromFirestore(snapshot.docs.first);
      } catch (e) {
        debugPrint('Error parsing open list: $e');
        return null;
      }
    }).handleError((error) {
      debugPrint('Error streaming open list: $error');
      return null;
    });
  }

  // Stream all sales lists (shared across all users)
  Stream<List<SalesListModel>> streamAllLists(String userId) {
    return _salesListsCollection.snapshots().map((snapshot) {
      debugPrint('Sales lists snapshot: ${snapshot.docs.length} documents');
      final lists = snapshot.docs
          .map((doc) {
            try {
              return SalesListModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing sales list: $e');
              return null;
            }
          })
          .whereType<SalesListModel>()
          .toList();

      // Sort by dateOpened in memory
      lists.sort((a, b) => b.dateOpened.compareTo(a.dateOpened));

      return lists;
    }).handleError((error) {
      debugPrint('Error streaming all lists: $error');
      return <SalesListModel>[];
    });
  }

  // Stream closed lists only (shared across all users)
  Stream<List<SalesListModel>> streamClosedLists(String userId) {
    return _salesListsCollection.snapshots().map((snapshot) {
      final lists = snapshot.docs
          .map((doc) {
            try {
              return SalesListModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing sales list: $e');
              return null;
            }
          })
          .whereType<SalesListModel>()
          .where((list) => !list.isOpen)
          .toList();

      // Sort by dateClosed in memory
      lists.sort((a, b) {
        final aDate = a.dateClosed ?? a.dateOpened;
        final bDate = b.dateClosed ?? b.dateOpened;
        return bDate.compareTo(aDate);
      });

      return lists;
    }).handleError((error) {
      debugPrint('Error streaming closed lists: $error');
      return <SalesListModel>[];
    });
  }

  // Stream items for a specific list (simplified - no orderBy to avoid index)
  Stream<List<SalesItemModel>> streamListItems(String listId) {
    return _salesItemsCollection
        .where('listId', isEqualTo: listId)
        .snapshots()
        .map((snapshot) {
      debugPrint('Sales items snapshot: ${snapshot.docs.length} documents');
      final items = snapshot.docs
          .map((doc) {
            try {
              return SalesItemModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing sales item: $e');
              return null;
            }
          })
          .whereType<SalesItemModel>()
          .toList();

      // Sort by createdAt in memory
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return items;
    }).handleError((error) {
      debugPrint('Error streaming list items: $error');
      return <SalesItemModel>[];
    });
  }

  // Get single list
  Future<SalesListModel?> getList(String listId) async {
    try {
      final doc = await _salesListsCollection.doc(listId).get();
      if (doc.exists) {
        return SalesListModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting list: $e');
      return null;
    }
  }

  // Get items for a specific list (non-stream version)
  Future<List<SalesItemModel>> getListItems(String listId) async {
    try {
      final snapshot =
          await _salesItemsCollection.where('listId', isEqualTo: listId).get();

      final items = snapshot.docs
          .map((doc) {
            try {
              return SalesItemModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing sales item: $e');
              return null;
            }
          })
          .whereType<SalesItemModel>()
          .toList();

      // Sort by createdAt
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return items;
    } catch (e) {
      debugPrint('Error getting list items: $e');
      return [];
    }
  }

  // Restore a deleted sales item (for undo functionality)
  Future<SalesItemModel> restoreSalesItem({
    required String listId,
    required String name,
    required double price,
    required int quantity,
    required DateTime createdAt,
  }) async {
    try {
      final docRef = await _salesItemsCollection.add({
        'listId': listId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'createdAt': Timestamp.fromDate(createdAt),
      });

      final itemTotal = price * quantity;

      // Update list total
      await _updateListTotal(listId, itemTotal);

      debugPrint('Sales item restored: ${docRef.id}');

      return SalesItemModel(
        id: docRef.id,
        listId: listId,
        name: name,
        price: price,
        quantity: quantity,
        createdAt: createdAt,
      );
    } catch (e) {
      debugPrint('Error restoring sales item: $e');
      rethrow;
    }
  }

  // Delete a closed sales list and all its items
  Future<void> deleteSalesList(String listId) async {
    try {
      // First, delete all items in the list
      final itemsSnapshot =
          await _salesItemsCollection.where('listId', isEqualTo: listId).get();

      final batch = _firestore.batch();

      for (var doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the list itself
      batch.delete(_salesListsCollection.doc(listId));

      await batch.commit();

      debugPrint(
          'Sales list and ${itemsSnapshot.docs.length} items deleted: $listId');
    } catch (e) {
      debugPrint('Error deleting sales list: $e');
      rethrow;
    }
  }

  // Clean up old closed sales lists - keep current month and previous month only (shared across all users)
  Future<void> cleanupOldSalesLists(String userId) async {
    try {
      final now = DateTime.now();
      // Calculate the cutoff date (start of previous month)
      // Keep: current month + previous month
      // Delete: anything before previous month
      final previousMonth = DateTime(now.year, now.month - 1, 1);
      final cutoffDate =
          previousMonth; // Lists before this date will be deleted

      debugPrint('Cleaning up sales lists older than: $cutoffDate');
      debugPrint(
          'Keeping lists from: ${previousMonth.month}/${previousMonth.year} and ${now.month}/${now.year}');

      // Get all closed lists (shared across all users)
      final snapshot =
          await _salesListsCollection.where('isOpen', isEqualTo: false).get();

      final listsToDelete = <DocumentSnapshot>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final dateClosed = data['dateClosed'] as Timestamp?;
          final dateOpened = data['dateOpened'] as Timestamp?;

          // Use dateClosed if available, otherwise use dateOpened
          final listDate = dateClosed?.toDate() ?? dateOpened?.toDate();

          if (listDate != null && listDate.isBefore(cutoffDate)) {
            listsToDelete.add(doc);
          }
        } catch (e) {
          debugPrint('Error checking list date: $e');
        }
      }

      if (listsToDelete.isEmpty) {
        debugPrint('No old sales lists to clean up');
        return;
      }

      debugPrint('Found ${listsToDelete.length} old sales lists to delete');

      // Delete each old list and its items
      for (var listDoc in listsToDelete) {
        await deleteSalesList(listDoc.id);
      }

      debugPrint(
          'Cleanup completed: ${listsToDelete.length} old lists deleted');
    } catch (e) {
      debugPrint('Error cleaning up old sales lists: $e');
      // Don't rethrow - cleanup is a background operation
    }
  }

  // Stream current month's sales total
  Stream<double> streamMonthlySalesTotal(String userId) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final docId = '${userId}_$monthKey';

    return _monthlySalesCollection
        .doc(docId)
        .snapshots()
        .map<double>((snapshot) {
      if (!snapshot.exists) return 0.0;
      final data = snapshot.data() as Map<String, dynamic>?;
      return (data?['totalAmount'] ?? 0).toDouble();
    }).handleError((error) {
      debugPrint('Error streaming monthly sales total: $error');
      return 0.0;
    });
  }

  // Get monthly sales details
  Stream<Map<String, dynamic>?> streamMonthlySalesDetails(String userId) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final docId = '${userId}_$monthKey';

    return _monthlySalesCollection.doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data() as Map<String, dynamic>?;
    }).handleError((error) {
      debugPrint('Error streaming monthly sales details: $error');
      return null;
    });
  }

  // Get today's sales total from all lists (shared across all users)
  Stream<double> streamTodaySalesTotal(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _salesListsCollection.snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        try {
          final list = SalesListModel.fromFirestore(doc);
          if (list.dateOpened.isAfter(startOfDay) ||
              list.dateOpened.isAtSameMomentAs(startOfDay)) {
            total += list.totalAmount;
          }
        } catch (e) {
          debugPrint('Error parsing list for total: $e');
        }
      }
      return total;
    }).handleError((error) {
      debugPrint('Error streaming today sales total: $error');
      return 0.0;
    });
  }
}
