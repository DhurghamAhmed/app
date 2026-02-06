import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../models/transaction_model.dart';
import '../../models/debtor_model.dart';
import '../../services/transaction_service.dart';
import '../../services/debtor_service.dart';
import '../../providers/auth_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _transactionService = TransactionService();
  final DebtorService _debtorService = DebtorService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userId;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(isDark),

            // Tab Bar
            _buildTabBar(isDark),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailySalesTab(isDark, userId),
                  _buildDebtorTransactionsTab(isDark, userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.accentOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.transactions,
                  style: AppTextStyles.headingMedium(),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.translate('todays_activity'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Cleanup Button
          GestureDetector(
            onTap: () => _showCleanupDialog(context, isDark),
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
                Icons.cleaning_services_outlined,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          labelStyle: AppTextStyles.labelLarge(),
          unselectedLabelStyle: AppTextStyles.labelLarge(),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.point_of_sale_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(context.l10n.translate('daily_sales')),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(context.l10n.debtors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesTab(bool isDark, String? userId) {
    if (userId == null) {
      return Center(child: Text(context.l10n.translate('please_sign_in')));
    }

    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.streamTodayTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter only sales
        final sales = (snapshot.data ?? [])
            .where((t) => t.type == TransactionType.sale)
            .toList();

        if (sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.translate('no_sales_today'),
                  style: AppTextStyles.titleMedium(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.translate('sales_will_appear'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingHorizontal,
          ),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionCard(
                title: sale.description ?? context.l10n.translate('sale'),
                subtitle: context.l10n.translate('sale_transaction'),
                amount: sale.amount,
                time: DateFormat('hh:mm a').format(sale.date),
                isPositive: true,
                icon: Icons.shopping_bag_outlined,
                iconColor: AppColors.success,
                isDark: isDark,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDebtorTransactionsTab(bool isDark, String? userId) {
    if (userId == null) {
      return Center(child: Text(context.l10n.translate('please_sign_in')));
    }

    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.streamDebtorTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.translate('no_debtor_transactions'),
                  style: AppTextStyles.titleMedium(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.translate('debt_payment_records'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingHorizontal,
          ),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isPayment = transaction.type == TransactionType.payment;
            final isEdit = transaction.type == TransactionType.edit;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: Key(transaction.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmation(
                      context, transaction, isDark);
                },
                onDismissed: (direction) {
                  _deleteTransaction(transaction);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.delete,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                child: _buildDebtorTransactionCard(
                  transaction: transaction,
                  title: transaction.typeDisplayName,
                  description: transaction.description ?? '',
                  amount: transaction.amount,
                  time: DateFormat('hh:mm a').format(transaction.date),
                  date: DateFormat('MMM dd').format(transaction.date),
                  isPayment: isPayment,
                  isEdit: isEdit,
                  isDark: isDark,
                  onTap: () =>
                      _showTransactionDetails(context, transaction, isDark),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String subtitle,
    required double amount,
    required String time,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
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
          ),

          // Amount
          Text(
            '${isPositive ? '+' : ''}IQD ${_formatAmount(amount)}',
            style: AppTextStyles.titleMedium(
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtorTransactionCard({
    required TransactionModel transaction,
    required String title,
    required String description,
    required double amount,
    required String time,
    required String date,
    required bool isPayment,
    bool isEdit = false,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    // Determine icon and color based on type
    IconData icon;
    Color color;
    String amountPrefix;

    if (isEdit) {
      icon = Icons.edit_outlined;
      color = AppColors.warning;
      amountPrefix = '';
    } else if (isPayment) {
      icon = Icons.arrow_downward_rounded;
      color = AppColors.success;
      amountPrefix = '+';
    } else {
      icon = Icons.arrow_upward_rounded;
      color = AppColors.error;
      amountPrefix = '-';
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium(),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Amount & Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (amountPrefix.isNotEmpty)
                        Text(
                          amountPrefix,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      Text(
                        'IQD ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _formatAmount(amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date • $time',
                    style: AppTextStyles.caption(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  /// Show transaction details bottom sheet
  void _showTransactionDetails(
      BuildContext context, TransactionModel transaction, bool isDark) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Determine transaction type info
    final isPayment = transaction.type == TransactionType.payment;
    final isEdit = transaction.type == TransactionType.edit;

    IconData icon;
    Color color;
    String typeTitle;
    String amountDisplay;

    if (isPayment) {
      icon = Icons.check_circle_outline_rounded;
      color = AppColors.success;
      typeTitle = context.l10n.translate('payment_received');
      amountDisplay = '+IQD ${_formatAmount(transaction.amount)}';
    } else if (isEdit) {
      icon = Icons.edit_outlined;
      color = AppColors.warning;
      typeTitle = context.l10n.translate('price_updated');
      amountDisplay = 'IQD ${_formatAmount(transaction.amount)}';
    } else {
      icon = Icons.add_circle_outline_rounded;
      color = AppColors.error;
      typeTitle = context.l10n.translate('debt_added');
      amountDisplay = '-IQD ${_formatAmount(transaction.amount)}';
    }

    // Get debtor info if available
    DebtorModel? debtor;
    if (transaction.referenceId != null) {
      try {
        final debtors =
            await _debtorService.streamDebtors(authProvider.userId ?? '').first;
        debtor =
            debtors.where((d) => d.id == transaction.referenceId).firstOrNull;
      } catch (e) {
        // Ignore error
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),

              // Type Title
              Text(typeTitle, style: AppTextStyles.headingSmall()),
              const SizedBox(height: 8),

              // Amount
              Text(
                amountDisplay,
                style: AppTextStyles.displaySmall(color: color),
              ),
              const SizedBox(height: 24),

              // Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Debtor Name
                    if (debtor != null) ...[
                      _buildDetailRow(
                        icon: Icons.person_outline_rounded,
                        label: context.l10n.translate('debtor'),
                        value: debtor.name,
                        valueColor: AppColors.primary,
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                    ],

                    // Description
                    _buildDetailRow(
                      icon: Icons.description_outlined,
                      label: context.l10n.translate('description'),
                      value:
                          _cleanDescription(transaction.description, context),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),

                    // Date
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: context.l10n.translate('date'),
                      value: DateFormat('EEEE, MMMM d, yyyy')
                          .format(transaction.date),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),

                    // Time
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: context.l10n.translate('time'),
                      value: DateFormat('hh:mm a').format(transaction.date),
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),

                    // Transaction Type
                    _buildDetailRow(
                      icon: Icons.category_outlined,
                      label: context.l10n.translate('type'),
                      value: transaction.typeDisplayName,
                      valueColor: color,
                      isDark: isDark,
                    ),

                    // Performed By
                    if (transaction.performedByUserName != null) ...[
                      _buildDivider(isDark),
                      _buildDetailRow(
                        icon: Icons.person_outline_rounded,
                        label: context.l10n.translate('performed_by'),
                        value: transaction.performedByUserName!,
                        valueColor: AppColors.primary,
                        isDark: isDark,
                      ),
                    ],

                    // Total Debt (if debtor exists)
                    if (debtor != null) ...[
                      _buildDivider(isDark),
                      _buildDetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: context.l10n.translate('total_debt'),
                        value: 'IQD ${_formatAmount(debtor.amount)}',
                        valueColor: AppColors.getDebtColor(debtor.amount),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.close,
                    style: AppTextStyles.labelLarge(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleSmall(
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  /// Clean description - remove person name
  String _cleanDescription(String? description, BuildContext context) {
    if (description == null || description.isEmpty) {
      return context.l10n.translate('no_description');
    }

    // Remove " - PersonName" pattern at the end
    final parts = description.split(' - ');
    if (parts.length > 1) {
      parts.removeLast();
      return parts.join(' - ');
    }

    return description;
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(
      BuildContext context, TransactionModel transaction, bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(context.l10n.translate('delete_transaction'),
                  style: AppTextStyles.headingSmall()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.translate('delete_transaction_confirm'),
                style: AppTextStyles.bodyMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTransactionIcon(transaction.type),
                        color: _getTransactionColor(transaction.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.typeDisplayName,
                            style: AppTextStyles.titleSmall(),
                          ),
                          Text(
                            'IQD ${_formatAmount(transaction.amount)}',
                            style: AppTextStyles.caption(
                              color: _getTransactionColor(transaction.type),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.translate('action_cannot_undo'),
                        style: AppTextStyles.caption(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                context.l10n.cancel,
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Delete transaction
  Future<void> _deleteTransaction(TransactionModel transaction) async {
    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transaction.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.translate('transaction_deleted')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.translate('error_deleting_transaction')}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Get transaction icon based on type
  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Icons.check_circle_outline_rounded;
      case TransactionType.edit:
        return Icons.edit_outlined;
      case TransactionType.debt:
        return Icons.add_circle_outline_rounded;
      case TransactionType.sale:
        return Icons.shopping_bag_outlined;
    }
  }

  /// Get transaction color based on type
  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return AppColors.success;
      case TransactionType.edit:
        return AppColors.warning;
      case TransactionType.debt:
        return AppColors.error;
      case TransactionType.sale:
        return AppColors.success;
    }
  }

  /// Show cleanup dialog
  void _showCleanupDialog(BuildContext context, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cleaning_services_outlined,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),

                Text(context.l10n.translate('cleanup_transactions'),
                    style: AppTextStyles.headingSmall()),
                const SizedBox(height: 6),
                Text(
                  context.l10n.translate('remove_old_transactions'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Cleanup Options
                _buildCleanupOption(
                  icon: Icons.looks_one_outlined,
                  title: context.l10n.translate('keep_last_30'),
                  subtitle: context.l10n.translate('delete_except_30'),
                  color: AppColors.success,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _performCleanup(userId, 30);
                  },
                ),
                const SizedBox(height: 10),
                _buildCleanupOption(
                  icon: Icons.looks_two_outlined,
                  title: context.l10n.translate('keep_last_50'),
                  subtitle: context.l10n.translate('delete_except_50'),
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _performCleanup(userId, 50);
                  },
                ),
                const SizedBox(height: 10),
                _buildCleanupOption(
                  icon: Icons.delete_sweep_outlined,
                  title: context.l10n.translate('delete_all'),
                  subtitle: context.l10n.translate('remove_all_warning'),
                  color: AppColors.error,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _confirmDeleteAll(context, userId, isDark);
                  },
                ),

                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCleanupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall()),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
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
    );
  }

  Future<void> _performCleanup(String userId, int keepCount) async {
    try {
      await _transactionService.cleanupOldTransactions(userId, keepCount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.translate('cleanup_complete')} $keepCount.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${context.l10n.translate('error_during_cleanup')}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAll(
      BuildContext context, String userId, bool isDark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(context.l10n.translate('delete_all_confirm'),
                  style: AppTextStyles.headingSmall()),
            ],
          ),
          content: Text(
            context.l10n.translate('delete_all_message'),
            style: AppTextStyles.bodyMedium(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                context.l10n.cancel,
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.translate('delete_all')),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteAllTransactions(userId);
    }
  }

  Future<void> _deleteAllTransactions(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.translate('deleted_transactions')} ${snapshot.docs.length}.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.translate('error_deleting_transactions')}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
