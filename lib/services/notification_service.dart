import '../models/notification_model.dart';
import '../models/debtor_model.dart';
import '../models/product_model.dart';
import 'debtor_service.dart';
import 'product_service.dart';

class NotificationService {
  final DebtorService _debtorService = DebtorService();
  final ProductService _productService = ProductService();

  // Configuration
  static const int _overdueDays =
      7; // Days after which debt is considered overdue
  static const double _highDebtThreshold = 100000; // High debt threshold
  static const int _lowStockThreshold = 5; // Low stock threshold

  /// Stream all notifications for a user (debts + inventory)
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    // Combine debtor and product streams
    return _debtorService.streamDebtors(userId).asyncExpand((debtors) {
      return _productService.streamProducts(userId).map((products) {
        final notifications = <NotificationModel>[];
        final now = DateTime.now();

        // ═══════════════════════════════════════════════════
        // DEBT NOTIFICATIONS
        // ═══════════════════════════════════════════════════
        for (final debtor in debtors) {
          if (debtor.amount <= 0) continue;

          final daysSinceCreated = now.difference(debtor.createdAt).inDays;

          // Overdue debt (> 7 days)
          if (daysSinceCreated >= _overdueDays) {
            notifications.add(NotificationModel(
              id: 'overdue_${debtor.id}',
              type: NotificationType.overdueDebt,
              priority: NotificationPriority.high,
              title: 'Overdue Debt',
              message:
                  '${debtor.name} owes IQD ${_formatNumber(debtor.amount)}',
              referenceId: debtor.id,
              createdAt: debtor.createdAt,
              data: {
                'debtorName': debtor.name,
                'amount': debtor.amount,
                'daysOverdue': daysSinceCreated,
              },
            ));
          }
          // High debt (> 100,000)
          else if (debtor.amount >= _highDebtThreshold) {
            notifications.add(NotificationModel(
              id: 'highdebt_${debtor.id}',
              type: NotificationType.highDebt,
              priority: NotificationPriority.medium,
              title: 'High Debt Amount',
              message:
                  '${debtor.name} owes IQD ${_formatNumber(debtor.amount)}',
              referenceId: debtor.id,
              createdAt: debtor.createdAt,
              data: {
                'debtorName': debtor.name,
                'amount': debtor.amount,
              },
            ));
          }
        }

        // ═══════════════════════════════════════════════════
        // INVENTORY NOTIFICATIONS
        // ═══════════════════════════════════════════════════
        for (final product in products) {
          // Out of stock (quantity = 0)
          if (product.quantity == 0) {
            notifications.add(NotificationModel(
              id: 'outofstock_${product.id}',
              type: NotificationType.outOfStock,
              priority: NotificationPriority.high,
              title: 'Out of Stock',
              message: '${product.name} is out of stock',
              referenceId: product.id,
              createdAt: product.createdAt,
              data: {
                'productName': product.name,
                'quantity': product.quantity,
              },
            ));
          }
          // Low stock (quantity < 5 and > 0)
          else if (product.quantity <= _lowStockThreshold) {
            notifications.add(NotificationModel(
              id: 'lowstock_${product.id}',
              type: NotificationType.lowStock,
              priority: NotificationPriority.medium,
              title: 'Low Stock',
              message: '${product.name} - Only ${product.quantity} left',
              referenceId: product.id,
              createdAt: product.createdAt,
              data: {
                'productName': product.name,
                'quantity': product.quantity,
              },
            ));
          }
        }

        // Sort by priority and date
        notifications.sort((a, b) {
          final priorityCompare = a.priority.index.compareTo(b.priority.index);
          if (priorityCompare != 0) return priorityCompare;
          return b.createdAt.compareTo(a.createdAt);
        });

        return notifications;
      });
    });
  }

  /// Stream notifications with inventory
  Stream<List<NotificationModel>> streamAllNotifications(String userId) async* {
    // For now, yield debtor notifications
    await for (final notifications in streamNotifications(userId)) {
      yield notifications;
    }
  }

  /// Stream notifications count for badge
  Stream<int> streamNotificationsCount(String userId) {
    return streamNotifications(userId)
        .map((notifications) => notifications.length);
  }

  /// Stream overdue debts only
  Stream<List<DebtorModel>> streamOverdueDebts(String userId) {
    return _debtorService.streamDebtors(userId).map((debtors) {
      final now = DateTime.now();
      return debtors.where((debtor) {
        if (debtor.amount <= 0) return false;
        final daysSinceCreated = now.difference(debtor.createdAt).inDays;
        return daysSinceCreated >= _overdueDays;
      }).toList();
    });
  }

  /// Stream high debt amounts
  Stream<List<DebtorModel>> streamHighDebts(String userId) {
    return _debtorService.streamDebtors(userId).map((debtors) {
      return debtors.where((debtor) {
        return debtor.amount >= _highDebtThreshold;
      }).toList();
    });
  }

  /// Stream low stock products
  Stream<List<ProductModel>> streamLowStockProducts(String userId) {
    return _productService.streamProducts(userId).map((products) {
      return products.where((product) {
        return product.quantity > 0 && product.quantity <= _lowStockThreshold;
      }).toList();
    });
  }

  /// Stream out of stock products
  Stream<List<ProductModel>> streamOutOfStockProducts(String userId) {
    return _productService.streamProducts(userId).map((products) {
      return products.where((product) {
        return product.quantity == 0;
      }).toList();
    });
  }

  /// Get notification summary
  Stream<Map<String, int>> streamNotificationSummary(String userId) async* {
    await for (final debtors in _debtorService.streamDebtors(userId)) {
      int overdueCount = 0;
      int highDebtCount = 0;
      final now = DateTime.now();

      for (final debtor in debtors) {
        if (debtor.amount <= 0) continue;

        final daysSinceCreated = now.difference(debtor.createdAt).inDays;

        if (daysSinceCreated >= _overdueDays) {
          overdueCount++;
        } else if (debtor.amount >= _highDebtThreshold) {
          highDebtCount++;
        }
      }

      yield {
        'overdue': overdueCount,
        'highDebt': highDebtCount,
        'total': overdueCount + highDebtCount,
      };
    }
  }

  /// Format number with thousand separators
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}
