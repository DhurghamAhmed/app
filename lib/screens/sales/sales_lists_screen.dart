import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../models/sales_list_model.dart';
import '../../services/sales_service.dart';
import '../../services/product_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SalesListsScreen extends StatefulWidget {
  const SalesListsScreen({super.key});

  @override
  State<SalesListsScreen> createState() => _SalesListsScreenState();
}

class _SalesListsScreenState extends State<SalesListsScreen> {
  final SalesService _salesService = SalesService();
  bool _isCreating = false;
  SalesListModel? _currentActiveList;

  // For undo functionality
  SalesItemModel? _lastDeletedItem;

  @override
  void initState() {
    super.initState();
    // Trigger cleanup of old sales lists when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerCleanup();
    });
  }

  void _triggerCleanup() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    // Only run cleanup if auto-cleanup is enabled in settings
    if (!settingsProvider.autoCleanupEnabled) {
      debugPrint('Auto-cleanup is disabled in settings');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId != null) {
      _salesService.cleanupOldSalesLists(userId);
    }
  }

  Future<void> _openNewList() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    if (_currentActiveList != null) {
      final items = await _salesService.getListItems(_currentActiveList!.id);
      if (items.isNotEmpty) {
        if (mounted) _showCloseListFirstDialog();
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      await _salesService.openNewSalesList(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.translate('new_sales_list_opened')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showCloseListFirstDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 32),
        ),
        title: Text(context.l10n.translate('close_list_first'),
            style: AppTextStyles.headingSmall()),
        content: Text(
          context.l10n.translate('close_list_first_message'),
          style: AppTextStyles.bodyMedium(),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildOpenListButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildActiveListSection(isDark, userId)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildClosedListsSection(isDark, userId)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.translate('sales_lists'),
                    style: AppTextStyles.headingMedium()),
                const SizedBox(height: 2),
                Text(
                  context.l10n.translate('manage_daily_sales'),
                  style: AppTextStyles.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenListButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingHorizontal),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.buttonShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isCreating ? null : _openNewList,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              child: _isCreating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.translate('open_new_sales_list'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveListSection(bool isDark, String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingHorizontal),
      child: StreamBuilder<SalesListModel?>(
        stream: _salesService.streamOpenList(userId),
        builder: (context, snapshot) {
          final activeList = snapshot.data;
          final bool hasActiveList = activeList != null;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_currentActiveList != activeList) {
              _currentActiveList = activeList;
            }
          });

          return Column(
            children: [
              const SizedBox(height: 0),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()))
              else if (!hasActiveList)
                AppCard(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_outlined,
                              size: 32, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.translate('no_active_sales_list'),
                          style: AppTextStyles.titleMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.translate('no_items_yet'),
                          style: AppTextStyles.bodySmall(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ActiveListCard(
                  salesList: activeList,
                  isDark: isDark,
                  onAddItem: () => _showAddItemDialog(activeList),
                  onClose: () => _closeList(activeList),
                  onViewItems: () => _showViewItemsSheet(activeList),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClosedListsSection(bool isDark, String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingHorizontal),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.translate('closed_lists'),
                      style: AppTextStyles.titleLarge()),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.translate('previous_sales_history'),
                    style: AppTextStyles.bodySmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<SalesListModel>>(
            stream: _salesService.streamClosedLists(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()));
              }

              final closedLists = snapshot.data ?? [];

              if (closedLists.isEmpty) {
                return AppCard(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.closedListIndicator
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 28,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.translate('no_closed_lists_yet'),
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

              return Column(
                children: closedLists
                    .map((list) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Dismissible(
                            key: Key(list.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await _showDeleteConfirmDialog();
                            },
                            onDismissed: (direction) {
                              _performDelete(list);
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
                                      color: Colors.white, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.delete,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: _ClosedListCard(
                                salesList: list,
                                isDark: isDark,
                                onView: () => _showListDetails(list)),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(SalesListModel salesList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddSaleItemSheet(
          salesList: salesList,
          salesService: _salesService,
        );
      },
    );
  }

  // View Items Sheet with Edit and Delete functionality
  void _showViewItemsSheet(SalesListModel salesList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.translate('all_items'),
                            style: AppTextStyles.headingSmall()),
                        StreamBuilder<SalesListModel?>(
                          stream:
                              _salesService.streamOpenList(salesList.userId),
                          builder: (context, snapshot) {
                            final currentList = snapshot.data;
                            final total = currentList?.totalAmount ??
                                salesList.totalAmount;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'IQD ${_formatAmount(total)}',
                                style: AppTextStyles.titleMedium(
                                    color: AppColors.success),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.translate('tap_to_edit_swipe_delete'),
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
              Expanded(
                child: StreamBuilder<List<SalesItemModel>>(
                  stream: _salesService.streamListItems(salesList.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n.translate('no_items_in_list'),
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
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await _showDeleteItemConfirmDialog();
                            },
                            onDismissed: (direction) {
                              _deleteItemWithUndo(item, salesList.id);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            child: AppCard(
                              onTap: () =>
                                  _showEditItemSheet(item, salesList.id),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: AppTextStyles.titleMedium(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'IQD ${NumberFormat('#,###', 'en_US').format(item.price.toInt())} × ${item.quantity}',
                                          style: AppTextStyles.caption(
                                            color: isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'IQD ${NumberFormat('#,###', 'en_US').format(item.total.toInt())}',
                                        style: AppTextStyles.titleMedium(
                                          color: AppColors.salesAmount,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Edit Item Sheet
  void _showEditItemSheet(SalesItemModel item, String listId) {
    final nameController = TextEditingController(text: item.name);
    final priceController =
        TextEditingController(text: item.price.toStringAsFixed(0));
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(context.l10n.translate('edit_item'),
                            style: AppTextStyles.headingSmall()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InputField(
                      label: context.l10n.translate('product_name'),
                      hint: context.l10n.translate('enter_product_name'),
                      controller: nameController,
                      prefixIcon: Icons.shopping_bag_outlined,
                      validator: (v) => v?.isEmpty == true
                          ? context.l10n.translate('required')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InputField(
                            label: context.l10n.translate('price_iqd'),
                            hint: '0',
                            controller: priceController,
                            prefixIcon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty == true) {
                                return context.l10n.translate('required');
                              }
                              if (double.tryParse(v!) == null) {
                                return context.l10n.translate('invalid');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputField(
                            label: context.l10n.translate('qty'),
                            hint: '1',
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty == true) {
                                return context.l10n.translate('required');
                              }
                              if (int.tryParse(v!) == null) {
                                return context.l10n.translate('invalid');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Builder(
                      builder: (buttonContext) {
                        // Pre-capture context-dependent values before any async operations
                        final navigator = Navigator.of(buttonContext);
                        final scaffoldMessenger =
                            ScaffoldMessenger.of(buttonContext);
                        final cancelText = buttonContext.l10n.cancel;
                        final saveChangesText =
                            buttonContext.l10n.translate('save_changes');
                        final itemUpdatedText =
                            buttonContext.l10n.translate('item_updated');

                        return Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: cancelText,
                                variant: ButtonVariant.outlined,
                                onPressed: () => navigator.pop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: saveChangesText,
                                leadingIcon: Icons.save_outlined,
                                isLoading: isLoading,
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setModalState(() => isLoading = true);

                                  try {
                                    await _salesService.updateSalesItem(
                                      itemId: item.id,
                                      listId: listId,
                                      name: nameController.text.trim(),
                                      price: double.parse(
                                          priceController.text.trim()),
                                      quantity: int.parse(
                                          quantityController.text.trim()),
                                    );
                                    navigator.pop();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(itemUpdatedText),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    setModalState(() => isLoading = false);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Delete Item Confirmation Dialog
  Future<bool> _showDeleteItemConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 32),
          ),
          title: Text(context.l10n.translate('remove_item'),
              style: AppTextStyles.headingSmall()),
          content: Text(
            context.l10n.translate('item_will_be_removed'),
            style: AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text(
                context.l10n.cancel,
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
    return confirm ?? false;
  }

  // Delete Item with Undo functionality
  void _deleteItemWithUndo(SalesItemModel item, String listId) {
    // Store the deleted item for potential undo
    _lastDeletedItem = item;

    // Delete the item
    _salesService.removeSalesItem(item.id, listId);

    // Show SnackBar with Undo option
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.translate('item_removed')),
        backgroundColor:
            isDark ? AppColors.surfaceDark : const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () async {
            if (_lastDeletedItem != null) {
              try {
                await _salesService.restoreSalesItem(
                  listId: listId,
                  name: _lastDeletedItem!.name,
                  price: _lastDeletedItem!.price,
                  quantity: _lastDeletedItem!.quantity,
                  createdAt: _lastDeletedItem!.createdAt,
                );
                _lastDeletedItem = null;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.translate('item_restored')),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error restoring item: $e');
              }
            }
          },
        ),
      ),
    );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> _closeList(SalesListModel salesList) async {
    // Pre-capture ALL context-dependent values BEFORE any async operations
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final salesListClosedText = context.l10n.translate('sales_list_closed');

    // Check if the list has any items
    final items = await _salesService.getListItems(salesList.id);

    // If the list is empty, delete it directly without saving
    if (items.isEmpty) {
      await _salesService.deleteSalesList(salesList.id);
      _currentActiveList = null;
      return; // No snackbar needed for empty lists
    }

    // If the list has items, show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.warning, size: 32),
          ),
          title: Text(dialogContext.l10n.translate('close_sales_list'),
              style: AppTextStyles.headingSmall()),
          content: Text(
            dialogContext.l10n.translate('close_list_message'),
            style: AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text(
                dialogContext.l10n.no,
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(dialogContext.l10n.yes),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Only pass userId for cleanup if auto-cleanup is enabled
      final userIdForCleanup =
          settingsProvider.autoCleanupEnabled ? authProvider.userId : null;
      await _salesService.closeSalesList(salesList.id,
          userId: userIdForCleanup);
      _currentActiveList = null;
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(salesListClosedText),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showListDetails(SalesListModel salesList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.translate('sales_list_details'),
                            style: AppTextStyles.headingSmall()),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'IQD ${_formatAmount(salesList.totalAmount)}',
                            style: AppTextStyles.titleMedium(
                                color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM/yyyy - hh:mm a')
                              .format(salesList.dateOpened),
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
              Expanded(
                child: StreamBuilder<List<SalesItemModel>>(
                  stream: _salesService.streamListItems(salesList.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          context.l10n.translate('no_items_in_list'),
                          style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _SalesItemTile(item: items[index], isDark: isDark),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 32),
          ),
          title: Text(context.l10n.translate('delete_sales_list'),
              style: AppTextStyles.headingSmall()),
          content: Text(
            context.l10n.translate('delete_list_message'),
            style: AppTextStyles.bodyMedium(),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text(
                context.l10n.cancel,
                style: AppTextStyles.labelLarge(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
    return confirm ?? false;
  }

  Future<void> _performDelete(SalesListModel salesList) async {
    try {
      await _salesService.deleteSalesList(salesList.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.translate('sales_list_deleted')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.translate('error_deleting_list')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) {
      return NumberFormat('#,###', 'en_US').format(amount.toInt());
    }
    return amount.toStringAsFixed(0);
  }
}

class _ActiveListCard extends StatelessWidget {
  final SalesListModel salesList;
  final bool isDark;
  final VoidCallback onAddItem;
  final VoidCallback onClose;
  final VoidCallback onViewItems;

  const _ActiveListCard({
    required this.salesList,
    required this.isDark,
    required this.onAddItem,
    required this.onClose,
    required this.onViewItems,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) {
      return NumberFormat('#,###', 'en_US').format(amount.toInt());
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final salesService = SalesService();

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(context.l10n.translate('active'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('IQD',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        Text(_formatAmount(salesList.totalAmount),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(salesList.dateOpened),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // View Items inline action
                    GestureDetector(
                      onTap: onViewItems,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.translate('view_items'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16)),
            ),
            child: Column(
              children: [
                StreamBuilder<List<SalesItemModel>>(
                  stream: salesService.streamListItems(salesList.id),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          context.l10n.translate('no_items_yet'),
                          style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }
                    return Column(
                        children: items
                            .take(5)
                            .map((item) =>
                                _SalesItemTile(item: item, isDark: isDark))
                            .toList());
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: onAddItem,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              context.l10n.translate('add_item'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: onClose,
                            icon: const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white),
                            label: Text(
                              context.l10n.translate('close_list'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedListCard extends StatelessWidget {
  final SalesListModel salesList;
  final bool isDark;
  final VoidCallback onView;

  const _ClosedListCard({
    required this.salesList,
    required this.isDark,
    required this.onView,
  });

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) {
      return NumberFormat('#,###', 'en_US').format(amount.toInt());
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onView,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.closedListIndicator.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                const Center(
                    child: Icon(Icons.receipt_outlined,
                        color: AppColors.closedListIndicator)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.closedListIndicator,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          width: 2),
                    ),
                    child:
                        const Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(salesList.dateOpened),
                    style: AppTextStyles.titleMedium()),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.closedListIndicator,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${context.l10n.translate('closed')} ${salesList.dateClosed != null ? DateFormat('hh:mm a').format(salesList.dateClosed!) : ''}',
                      style: AppTextStyles.caption(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('IQD ${_formatAmount(salesList.totalAmount)}',
                  style:
                      AppTextStyles.titleLarge(color: AppColors.salesAmount)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_left_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textTertiaryDark.withValues(alpha: 0.5)
                          : AppColors.textTertiaryLight.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Icon(Icons.visibility_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesItemTile extends StatelessWidget {
  final SalesItemModel item;
  final bool isDark;

  const _SalesItemTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.titleSmall()),
                Text(
                  'IQD ${NumberFormat('#,###', 'en_US').format(item.price.toInt())} x ${item.quantity}',
                  style: AppTextStyles.caption(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                ),
              ],
            ),
          ),
          Text(
              'IQD ${NumberFormat('#,###', 'en_US').format(item.total.toInt())}',
              style: AppTextStyles.titleMedium()),
        ],
      ),
    );
  }
}

/// Unified suggestion model that tracks source (list vs inventory)
enum SuggestionSource { salesList, inventory }

class _SuggestionItem {
  final String name;
  final double price;
  final int? quantity; // Available quantity (for inventory)
  final SuggestionSource source;
  final String? productId; // For inventory items to decrease stock

  _SuggestionItem({
    required this.name,
    required this.price,
    this.quantity,
    required this.source,
    this.productId,
  });
}

/// Smart Add Sale Item Sheet with Product Autocomplete
class _AddSaleItemSheet extends StatefulWidget {
  final SalesListModel salesList;
  final SalesService salesService;

  const _AddSaleItemSheet({
    required this.salesList,
    required this.salesService,
  });

  @override
  State<_AddSaleItemSheet> createState() => _AddSaleItemSheetState();
}

class _AddSaleItemSheetState extends State<_AddSaleItemSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ProductService _productService = ProductService();

  List<_SuggestionItem> _allSuggestions = [];
  List<_SuggestionItem> _filteredSuggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  bool _isAddingItem = false;
  _SuggestionItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _loadAllItems();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _nameFocusNode.dispose();
    _priceFocusNode.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _loadAllItems() {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Load both sources
    List<_SuggestionItem> listItems = [];
    List<_SuggestionItem> inventoryItems = [];
    bool listLoaded = false;
    bool inventoryLoaded = false;

    void updateSuggestions() {
      if (listLoaded && inventoryLoaded && mounted) {
        // Combine both sources - INVENTORY items have priority and always show
        final List<_SuggestionItem> combinedItems = [];
        final Set<String> addedNames = {};

        // Add inventory items FIRST (they have priority - marked with star)
        for (final item in inventoryItems) {
          combinedItems.add(item);
          addedNames.add(item.name.toLowerCase());
        }

        // Add list items that are NOT in inventory (to avoid duplicates)
        for (final item in listItems) {
          if (!addedNames.contains(item.name.toLowerCase())) {
            combinedItems.add(item);
            addedNames.add(item.name.toLowerCase());
          }
        }

        setState(() {
          _allSuggestions = combinedItems;
          _isLoading = false;
        });
      }
    }

    // Stream items from the current open sales list
    widget.salesService.streamListItems(widget.salesList.id).listen((items) {
      if (mounted) {
        // Get unique items by name
        final Map<String, SalesItemModel> uniqueListItems = {};
        for (final item in items) {
          if (!uniqueListItems.containsKey(item.name.toLowerCase())) {
            uniqueListItems[item.name.toLowerCase()] = item;
          }
        }

        listItems = uniqueListItems.values
            .map((item) => _SuggestionItem(
                  name: item.name,
                  price: item.price,
                  source: SuggestionSource.salesList,
                ))
            .toList();

        listLoaded = true;
        updateSuggestions();
      }
    });

    // Stream products from inventory
    _productService.streamProducts(userId).listen((products) {
      if (mounted) {
        inventoryItems = products
            .where((p) => p.quantity > 0) // Only show products with stock
            .map((product) => _SuggestionItem(
                  name: product.name,
                  price: product.price,
                  quantity: product.quantity,
                  source: SuggestionSource.inventory,
                  productId: product.id,
                ))
            .toList();

        inventoryLoaded = true;
        updateSuggestions();
      }
    });
  }

  void _onNameChanged() {
    final query = _nameController.text.trim().toLowerCase();

    // Clear selected item when user types
    if (_selectedItem != null && _nameController.text != _selectedItem!.name) {
      _selectedItem = null;
    }

    if (query.isNotEmpty) {
      // Case-insensitive client-side filtering from all suggestions
      final filtered = _allSuggestions
          .where((item) => item.name.toLowerCase().contains(query))
          .take(6) // Limit to 6 suggestions
          .toList();

      setState(() {
        _filteredSuggestions = filtered;
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectItem(_SuggestionItem item) {
    setState(() {
      _selectedItem = item;
      _nameController.text = item.name;
      _priceController.text = item.price.toStringAsFixed(0);
      _showSuggestions = false;
    });

    // Auto-focus quantity field after selection
    Future.delayed(const Duration(milliseconds: 100), () {
      _quantityFocusNode.requestFocus();
      // Select all text in quantity field for easy replacement
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    });
  }

  // Open barcode scanner to find product
  void _openBarcodeScanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.translate('scan_barcode'),
                                    style: AppTextStyles.titleMedium(),
                                  ),
                                  Text(
                                    context.l10n
                                        .translate('scan_product_barcode'),
                                    style: AppTextStyles.caption(
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(
                                Icons.close_rounded,
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MobileScanner(
                          onDetect: (capture) async {
                            if (isProcessing) return;

                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final String? code = barcodes.first.rawValue;
                              if (code != null && code.isNotEmpty) {
                                isProcessing = true;
                                await _handleScannedBarcodeWithDialog(
                                    code, ctx);
                                isProcessing = false;
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Handle scanned barcode with dialog - search for product
  Future<void> _handleScannedBarcodeWithDialog(
      String barcode, BuildContext scannerContext) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;

    if (userId == null) return;

    // Search for product by barcode in inventory
    final product =
        await _productService.getProductByBarcodeId(barcode, userId);

    if (!mounted) return;

    if (product != null) {
      // Product found - close scanner and fill in the form
      Navigator.pop(scannerContext);

      setState(() {
        _selectedItem = _SuggestionItem(
          name: product.name,
          price: product.price,
          quantity: product.quantity,
          source: SuggestionSource.inventory,
          productId: product.id,
        );
        _nameController.text = product.name;
        _priceController.text = product.price.toStringAsFixed(0);
        _showSuggestions = false;
      });

      // Focus on quantity field
      Future.delayed(const Duration(milliseconds: 100), () {
        _quantityFocusNode.requestFocus();
        _quantityController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _quantityController.text.length,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${context.l10n.translate('product_found')}: ${product.name}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // Product not found - show dialog with options
      _showBarcodeNotFoundDialog(scannerContext, barcode);
    }
  }

  // Show dialog when barcode not found
  void _showBarcodeNotFoundDialog(BuildContext scannerContext, String barcode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: scannerContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.translate('barcode_not_found'),
                style: AppTextStyles.headingSmall(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.translate('barcode_not_in_inventory'),
                style: AppTextStyles.bodyMedium(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.cardDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  barcode,
                  style: AppTextStyles.caption(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(scannerContext); // Close scanner
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.translate('close'),
                        style: AppTextStyles.labelLarge(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                            dialogContext); // Close dialog only, scanner stays open
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.translate('try_again')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quantity = int.parse(_quantityController.text.trim());

    // Store context-dependent values before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notEnoughStockText = context.l10n.translate('not_enough_stock');
    final failedToUpdateInventoryText =
        context.l10n.translate('failed_to_update_inventory');
    final itemAddedInventoryDecreasedText =
        context.l10n.translate('item_added_inventory_decreased');

    setState(() => _isAddingItem = true);

    try {
      // If selected from inventory, check and decrease stock
      if (_selectedItem != null &&
          _selectedItem!.source == SuggestionSource.inventory &&
          _selectedItem!.productId != null) {
        // Check if enough stock
        if (_selectedItem!.quantity != null &&
            quantity > _selectedItem!.quantity!) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('$notEnoughStockText ${_selectedItem!.quantity}'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() => _isAddingItem = false);
          return;
        }

        // Decrease inventory
        final success = await _productService.decreaseProductQuantity(
          _selectedItem!.productId!,
          quantity,
        );

        if (!mounted) return;

        if (!success) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(failedToUpdateInventoryText),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() => _isAddingItem = false);
          return;
        }
      }

      // Add the sales item
      await widget.salesService.addSalesItem(
        listId: widget.salesList.id,
        userId: authProvider.userId!,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: quantity,
      );

      if (!mounted) return;

      // Show success message if from inventory
      if (_selectedItem != null &&
          _selectedItem!.source == SuggestionSource.inventory) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$itemAddedInventoryDecreasedText $quantity'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingItem = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.translate('add_sale_item'),
                            style: AppTextStyles.headingSmall()),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.translate('search_list_or_inventory'),
                          style: AppTextStyles.caption(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  // Scan Barcode Button
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openBarcodeScanner(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product Name Field with Autocomplete
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check if selected item is from inventory for styling
                  Builder(
                    builder: (context) {
                      final bool isInventorySelected = _selectedItem != null &&
                          _selectedItem!.source == SuggestionSource.inventory;
                      final bool isArabic = context.isArabic;

                      return Stack(
                        children: [
                          InputField(
                            label: context.l10n.translate('product_name'),
                            hint: context.l10n
                                .translate('start_typing_to_search'),
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            prefixIcon: Icons.shopping_bag_outlined,
                            validator: (v) => v?.isEmpty == true
                                ? context.l10n.translate('required')
                                : null,
                            onTap: () {
                              if (_nameController.text.isNotEmpty) {
                                _onNameChanged();
                              }
                            },
                          ),
                          if (_selectedItem != null)
                            Positioned(
                              // For Arabic (RTL), position at start (left), for LTR position at end (right)
                              left: isArabic ? 12 : null,
                              right: isArabic ? null : 12,
                              top: 38,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isInventorySelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.inventory_2_rounded,
                                        color: AppColors.secondary,
                                        size: 18,
                                      ),
                                    ),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: isInventorySelected
                                        ? AppColors.secondary
                                        : AppColors.success,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Suggestions Dropdown
                  if (_showSuggestions)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            // Unified suggestions from both sources
                            ..._filteredSuggestions
                                .map((item) => _UnifiedSuggestionTile(
                                      item: item,
                                      isDark: isDark,
                                      onTap: () => _selectItem(item),
                                    )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Price and Quantity Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InputField(
                      label: context.l10n.translate('price_iqd'),
                      hint: '0',
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty == true) {
                          return context.l10n.translate('required');
                        }
                        if (double.tryParse(v!) == null) {
                          return context.l10n.translate('invalid');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputField(
                      label: context.l10n.translate('qty'),
                      hint: '1',
                      controller: _quantityController,
                      focusNode: _quantityFocusNode,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty == true) {
                          return context.l10n.translate('required');
                        }
                        if (int.tryParse(v!) == null) {
                          return context.l10n.translate('invalid');
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // Stock indicator for inventory items - more visible
              if (_selectedItem != null &&
                  _selectedItem!.source == SuggestionSource.inventory &&
                  _selectedItem!.quantity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${context.l10n.translate('available_stock')}: ${_selectedItem!.quantity}',
                          style: AppTextStyles.bodySmall(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: context.l10n.translate('add_item'),
                  leadingIcon: Icons.add_rounded,
                  isLoading: _isAddingItem,
                  onPressed: _addItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified Suggestion Tile Widget
class _UnifiedSuggestionTile extends StatelessWidget {
  final _SuggestionItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _UnifiedSuggestionTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInventory = item.source == SuggestionSource.inventory;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isInventory
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isInventory
                    ? Icons.inventory_2_rounded
                    : Icons.receipt_long_rounded,
                color: isInventory ? AppColors.secondary : AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'IQD ${NumberFormat('#,###', 'en_US').format(item.price.toInt())}',
                        style: AppTextStyles.caption(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      if (isInventory && item.quantity != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.quantity} ${context.l10n.translate('in_stock')}',
                            style: AppTextStyles.caption(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
