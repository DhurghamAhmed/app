import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for products
  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  /// Get product by barcode ID (shared across all users)
  Future<ProductModel?> getProductByBarcodeId(
      String barcodeId, String userId) async {
    try {
      final querySnapshot = await _productsCollection
          .where('barcodeId', isEqualTo: barcodeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ProductModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      debugPrint('Error getting product by barcode: $e');
      return null;
    }
  }

  /// Add a new product to inventory
  Future<ProductModel> addProduct({
    required String name,
    required double price,
    required int quantity,
    required String barcodeId,
    required String userId,
  }) async {
    try {
      final docRef = await _productsCollection.add({
        'name': name,
        'price': price,
        'quantity': quantity,
        'barcodeId': barcodeId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get the created document
      final doc = await docRef.get();
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  /// Update product quantity (add to existing quantity)
  Future<void> updateProductQuantity(
      String productId, int additionalQuantity) async {
    try {
      await _productsCollection.doc(productId).update({
        'quantity': FieldValue.increment(additionalQuantity),
      });
    } catch (e) {
      debugPrint('Error updating product quantity: $e');
      rethrow;
    }
  }

  /// Decrease product quantity (for sales)
  /// Returns true if successful, false if not enough stock
  Future<bool> decreaseProductQuantity(
      String productId, int quantityToDecrease) async {
    try {
      // First check if there's enough stock
      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return false;

      final currentQuantity = doc.data()?['quantity'] ?? 0;
      if (currentQuantity < quantityToDecrease) {
        return false; // Not enough stock
      }

      await _productsCollection.doc(productId).update({
        'quantity': FieldValue.increment(-quantityToDecrease),
      });
      return true;
    } catch (e) {
      debugPrint('Error decreasing product quantity: $e');
      return false;
    }
  }

  /// Update product details
  Future<void> updateProduct({
    required String productId,
    String? name,
    double? price,
    int? quantity,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price;
      if (quantity != null) updates['quantity'] = quantity;

      if (updates.isNotEmpty) {
        await _productsCollection.doc(productId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  /// Stream all products (shared across all users)
  Stream<List<ProductModel>> streamProducts(String userId) {
    return _productsCollection.snapshots().map((snapshot) {
      final products =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      // Sort locally to avoid needing a composite index
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }
}
