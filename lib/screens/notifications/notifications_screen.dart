import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/debtor_service.dart';
import '../debtor/add_debtor_screen.dart';
import '../inventory/inventory_scanner_screen.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isDark),
            Expanded(
              child: _buildNotificationsList(context, isDark, userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.notifications,
                    style: AppTextStyles.headingMedium()),
                const SizedBox(height: 2),
                Text(
                  context.l10n.translate('stay_updated'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Notification Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      BuildContext context, bool isDark, String userId) {
    final notificationService = NotificationService();

    return StreamBuilder<List<NotificationModel>>(
      stream: notificationService.streamNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        // Group notifications
        final todayNotifications =
            notifications.where((n) => n.isToday).toList();
        final weekNotifications =
            notifications.where((n) => !n.isToday && n.isThisWeek).toList();
        final olderNotifications =
            notifications.where((n) => !n.isThisWeek).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              _buildSummaryCard(context, isDark, notifications),
              const SizedBox(height: 24),

              // Today's Notifications
              if (todayNotifications.isNotEmpty) ...[
                _buildSectionHeader(context.l10n.translate('today'),
                    todayNotifications.length, isDark),
                const SizedBox(height: 12),
                ...todayNotifications
                    .map((n) => _buildNotificationCard(context, n, isDark)),
                const SizedBox(height: 20),
              ],

              // This Week
              if (weekNotifications.isNotEmpty) ...[
                _buildSectionHeader(context.l10n.translate('this_week'),
                    weekNotifications.length, isDark),
                const SizedBox(height: 12),
                ...weekNotifications
                    .map((n) => _buildNotificationCard(context, n, isDark)),
                const SizedBox(height: 20),
              ],

              // Older
              if (olderNotifications.isNotEmpty) ...[
                _buildSectionHeader(context.l10n.translate('earlier'),
                    olderNotifications.length, isDark),
                const SizedBox(height: 12),
                ...olderNotifications
                    .map((n) => _buildNotificationCard(context, n, isDark)),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 50,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.translate('all_caught_up'),
            style: AppTextStyles.headingSmall(),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.translate('no_pending_notifications'),
            style: AppTextStyles.bodyMedium(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isDark,
      List<NotificationModel> notifications) {
    // Count by category
    final debtNotifications = notifications
        .where((n) =>
            n.type == NotificationType.overdueDebt ||
            n.type == NotificationType.highDebt)
        .length;
    final stockNotifications = notifications
        .where((n) =>
            n.type == NotificationType.lowStock ||
            n.type == NotificationType.outOfStock)
        .length;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Total
          Expanded(
            child: _buildSummaryItem(
              count: notifications.length,
              label: context.l10n.translate('total'),
              color: AppColors.primary,
              icon: Icons.notifications_rounded,
              isDark: isDark,
            ),
          ),
          _buildDivider(isDark),
          // Debts
          Expanded(
            child: _buildSummaryItem(
              count: debtNotifications,
              label: context.l10n.translate('debts'),
              color: AppColors.error,
              icon: Icons.account_balance_wallet_rounded,
              isDark: isDark,
            ),
          ),
          _buildDivider(isDark),
          // Stock
          Expanded(
            child: _buildSummaryItem(
              count: stockNotifications,
              label: context.l10n.translate('stock'),
              color: AppColors.warning,
              icon: Icons.inventory_2_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(icon, color: color, size: 22),
              ),
              if (count > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 60,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.titleLarge(),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.labelSmall(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification, bool isDark) {
    final color = Color(notification.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _handleNotificationTap(context, notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(notification.type),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Priority indicator
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.titleSmall(),
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: AppTextStyles.caption(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Extra info badges
                      if (notification.data != null) ...[
                        const SizedBox(height: 8),
                        _buildNotificationBadge(context, notification, color),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.overdueDebt:
        return Icons.warning_amber_rounded;
      case NotificationType.highDebt:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.lowStock:
        return Icons.inventory_2_outlined;
      case NotificationType.outOfStock:
        return Icons.remove_shopping_cart_outlined;
      case NotificationType.dailySummary:
        return Icons.analytics_outlined;
      case NotificationType.reminder:
        return Icons.notifications_outlined;
    }
  }

  Widget _buildNotificationBadge(
      BuildContext context, NotificationModel notification, Color color) {
    String badgeText;
    IconData badgeIcon;

    switch (notification.type) {
      case NotificationType.overdueDebt:
        final days = notification.data?['daysOverdue'] ?? 0;
        badgeText = '$days ${context.l10n.translate('days_overdue')}';
        badgeIcon = Icons.schedule_rounded;
        break;
      case NotificationType.highDebt:
        badgeText = context.l10n.translate('high_amount');
        badgeIcon = Icons.trending_up_rounded;
        break;
      case NotificationType.lowStock:
        final qty = notification.data?['quantity'] ?? 0;
        badgeText =
            '${context.l10n.translate('only_left')} $qty ${context.l10n.translate('left')}';
        badgeIcon = Icons.inventory_outlined;
        break;
      case NotificationType.outOfStock:
        badgeText = context.l10n.translate('restock_needed');
        badgeIcon = Icons.add_shopping_cart_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: AppTextStyles.labelSmall(color: color),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) async {
    final referenceId = notification.referenceId;
    if (referenceId == null) return;

    switch (notification.type) {
      // Debt notifications - navigate to debtor details
      case NotificationType.overdueDebt:
      case NotificationType.highDebt:
        await _navigateToDebtorDetails(context, referenceId);
        break;

      // Stock notifications - navigate to inventory
      case NotificationType.lowStock:
      case NotificationType.outOfStock:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScannerScreen()),
        );
        break;

      default:
        break;
    }
  }

  Future<void> _navigateToDebtorDetails(
      BuildContext context, String debtorId) async {
    final debtorService = DebtorService();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get debtor data
      final debtors = await debtorService
          .streamDebtors(
            Provider.of<AuthProvider>(context, listen: false).userId ?? '',
          )
          .first;

      final debtor = debtors.where((d) => d.id == debtorId).firstOrNull;

      // Close loading
      if (context.mounted) Navigator.pop(context);

      if (debtor != null && context.mounted) {
        // Navigate to debtor details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DebtorDetailsScreen(debtor: debtor),
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.translate('debtor_not_found')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
