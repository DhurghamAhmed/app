/// Notification types
enum NotificationType {
  overdueDebt,    // Debt > 7 days
  highDebt,       // Debt > 100,000
  lowStock,       // Stock < 5
  outOfStock,     // Stock = 0
  dailySummary,   // Daily summary
  reminder,       // General reminder
}

/// Notification priority
enum NotificationPriority {
  high,
  medium,
  low,
}

/// Notification model
class NotificationModel {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? referenceId; // debtorId, productId, etc.
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Extra data

  NotificationModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.referenceId,
    required this.createdAt,
    this.data,
  });

  /// Get icon based on type
  String get iconName {
    switch (type) {
      case NotificationType.overdueDebt:
        return 'warning';
      case NotificationType.highDebt:
        return 'account_balance_wallet';
      case NotificationType.lowStock:
        return 'inventory';
      case NotificationType.outOfStock:
        return 'remove_shopping_cart';
      case NotificationType.dailySummary:
        return 'analytics';
      case NotificationType.reminder:
        return 'notifications';
    }
  }

  /// Get color hex based on priority
  int get colorHex {
    switch (priority) {
      case NotificationPriority.high:
        return 0xFFEF4444; // Red
      case NotificationPriority.medium:
        return 0xFFF59E0B; // Orange
      case NotificationPriority.low:
        return 0xFF10B981; // Green
    }
  }

  /// Check if notification is from today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Check if notification is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return createdAt.isAfter(weekAgo);
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}