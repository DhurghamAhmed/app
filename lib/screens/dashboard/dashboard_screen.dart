import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../models/debtor_model.dart';
import '../../services/debtor_service.dart';
import '../../services/transaction_service.dart';
import '../../services/sales_service.dart';
import '../../providers/auth_provider.dart';
import '../debtor/add_debtor_screen.dart';
import '../sales/sales_lists_screen.dart';
import '../transactions/transactions_screen.dart';
import '../settings/settings_screen.dart';
import '../inventory/inventory_scanner_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      const _DashboardHome(),
      const AddDebtorScreen(),
      const SalesListsScreen(),
      const InventoryScannerScreen(),
      const TransactionsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded, l10n.home, isDark),
                  _buildNavItem(
                      1, Icons.person_add_rounded, l10n.debtors, isDark),
                  _buildNavItem(
                      2, Icons.receipt_long_rounded, l10n.sales, isDark),
                  _buildNavItem(
                      3, Icons.qr_code_scanner_rounded, l10n.inventory, isDark),
                  _buildNavItem(
                      4, Icons.swap_horiz_rounded, l10n.history, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium(
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Dashboard Home Content
class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userId;

    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(context, isDark, authProvider),
            ),

            // Section 1: Today's Summary (Hero Card)
            SliverToBoxAdapter(
              child: _buildTodaySummaryCard(context, isDark, userId),
            ),

            // Section 2: Overview Grid (2x2)
            SliverToBoxAdapter(
              child: _buildOverviewGrid(context, userId),
            ),

            // Section 3: Recent Activity
            SliverToBoxAdapter(
              child: _buildRecentActivitySection(context, isDark, userId),
            ),

            // Section 4: Top Debtors
            SliverToBoxAdapter(
              child: _buildTopDebtorsSection(context, isDark, userId),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
      BuildContext context, bool isDark, String? userId) {
    if (userId == null) {
      return const SizedBox(width: 48, height: 48);
    }

    final notificationService = NotificationService();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
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
        child: StreamBuilder<int>(
          stream: notificationService.streamNotificationsCount(userId),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;

            return Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, bool isDark, AuthProvider authProvider) {
    final userName = authProvider.userModel?.fullName ??
        authProvider.user?.displayName ??
        'User';

    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.l10n.welcomeBack} 👋',
                  style: AppTextStyles.bodyMedium(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: AppTextStyles.headingMedium(),
                ),
              ],
            ),
          ),
          // Notification Button with dynamic badge
          _buildNotificationButton(context, isDark, authProvider.userId),
          const SizedBox(width: 8),
          // Settings Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
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
              child: Center(
                child: Icon(
                  Icons.settings_outlined,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: TODAY'S SUMMARY - Hero Card (Main Focus)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodaySummaryCard(
      BuildContext context, bool isDark, String userId) {
    final transactionService = TransactionService();

    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: StreamBuilder<double>(
        stream: transactionService.streamTodaySalesTotal(userId),
        builder: (context, snapshot) {
          final todaySales = snapshot.data ?? 0;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.today_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.todaysPerformance,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            todaySales > 0
                                ? Icons.trending_up_rounded
                                : Icons.remove_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            todaySales > 0
                                ? context.l10n.translate('active')
                                : context.l10n.translate('no_sales'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Main Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.totalSales,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'IQD',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatNumber(todaySales),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: OVERVIEW GRID
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewGrid(BuildContext context, String userId) {
    final debtorService = DebtorService();
    final salesService = SalesService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPaddingHorizontal,
      ),
      child: Column(
        children: [
          // Monthly Sales - Full Width Card (from closed lists)
          StreamBuilder<double>(
            stream: salesService.streamMonthlySalesTotal(userId),
            builder: (context, snapshot) {
              final monthlySales = snapshot.data ?? 0;
              return _buildFullWidthCard(
                context: context,
                title: context.l10n.monthlySales,
                value: 'IQD ${_formatNumber(monthlySales)}',
                icon: Icons.calendar_month_rounded,
                color: AppColors.salesAmount,
                isDark: isDark,
              );
            },
          ),

          const SizedBox(height: 12),

          // Row: Total Debts & Number of Debtors
          Row(
            children: [
              // Total Debts
              Expanded(
                child: StreamBuilder<double>(
                  stream: debtorService.streamTotalDebt(userId),
                  builder: (context, snapshot) {
                    final totalDebts = snapshot.data ?? 0;
                    final debtColor = AppColors.getDebtColor(totalDebts);
                    return _buildOverviewCard(
                      context: context,
                      title: context.l10n.totalDebts,
                      value: 'IQD ${_formatNumber(totalDebts)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: debtColor,
                      isDark: isDark,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Number of Debtors
              Expanded(
                child: StreamBuilder<int>(
                  stream: debtorService.streamDebtorsCount(userId),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildOverviewCard(
                      context: context,
                      title: context.l10n.debtors,
                      value: count.toString(),
                      icon: Icons.people_outline_rounded,
                      color: AppColors.accentOrange,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Full Width Card for Monthly Sales
  Widget _buildFullWidthCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.headingMedium(color: color),
                ),
              ],
            ),
          ),
          Icon(
            Icons.trending_up_rounded,
            color: color.withValues(alpha: 0.5),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.caption(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleLarge(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentActivitySection(
      BuildContext context, bool isDark, String userId) {
    final transactionService = TransactionService();
    final debtorService = DebtorService();

    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.translate('recent_activity'),
                      style: AppTextStyles.headingSmall()),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.translate('your_latest_transactions'),
                    style: AppTextStyles.caption(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Activity Cards
          Row(
            children: [
              // Last Sale
              Expanded(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: transactionService.streamLastSale(userId),
                  builder: (context, snapshot) {
                    final lastSale = snapshot.data;
                    return _buildActivityCard(
                      title: context.l10n.translate('last_sale'),
                      value: lastSale != null
                          ? 'IQD ${_formatNumber(lastSale['amount'] ?? 0)}'
                          : context.l10n.translate('no_sales_yet'),
                      subtitle: lastSale != null
                          ? _formatTimeAgo(lastSale['date'], context)
                          : context.l10n.translate('start_selling'),
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.salesAmount,
                      isDark: isDark,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Last Debt Added
              Expanded(
                child: StreamBuilder<DebtorModel?>(
                  stream: debtorService.streamLastDebtor(userId),
                  builder: (context, snapshot) {
                    final lastDebtor = snapshot.data;
                    return _buildActivityCard(
                      title: context.l10n.translate('last_debt'),
                      value: lastDebtor != null
                          ? 'IQD ${_formatNumber(lastDebtor.amount)}'
                          : context.l10n.translate('no_debts_yet'),
                      subtitle: lastDebtor != null
                          ? lastDebtor.name
                          : context.l10n.translate('add_debtor'),
                      icon: Icons.person_add_outlined,
                      color: AppColors.debtAmount,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.labelMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.titleMedium(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return context.l10n.translate('just_now');
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${context.l10n.translate('minutes_ago')}';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}${context.l10n.translate('hours_ago')}';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}${context.l10n.translate('days_ago')}';
    }
    return DateFormat('MMM d', context.isArabic ? 'ar' : 'en').format(date);
  }

  /// Format number with thousand separators (full number)
  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    }
    return NumberFormat('#,###', 'en_US').format(number.toInt());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4: TOP DEBTORS (Lighter Visual)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopDebtorsSection(
      BuildContext context, bool isDark, String userId) {
    final debtorService = DebtorService();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenPaddingHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.debtAmount.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      color: AppColors.debtAmount,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(context.l10n.topDebtors,
                      style: AppTextStyles.titleLarge()),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddDebtorScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.translate('view_all'),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Debtor List
          StreamBuilder<List<DebtorModel>>(
            stream: debtorService.streamTopDebtors(userId, limit: 3),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final debtors = snapshot.data ?? [];

              if (debtors.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 40,
                          color: AppColors.success.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.translate('no_outstanding_debts'),
                          style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: debtors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final debtor = entry.value;
                    final isLast = index == debtors.length - 1;

                    return _buildCompactDebtorItem(
                      context: context,
                      debtor: debtor,
                      isDark: isDark,
                      showDivider: !isLast,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDebtorItem({
    required BuildContext context,
    required DebtorModel debtor,
    required bool isDark,
    required bool showDivider,
  }) {
    // Red if >= 100,000, black otherwise
    final bool isHighDebt = debtor.amount >= 100000;
    final Color amountColor = isHighDebt
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DebtorDetailsScreen(debtor: debtor),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        debtor.initials,
                        style:
                            AppTextStyles.labelLarge(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name only
                  Expanded(
                    child: Text(
                      debtor.name,
                      style: AppTextStyles.titleMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Amount
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'IQD ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: amountColor.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _formatNumber(debtor.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 70,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
      ],
    );
  }
}
