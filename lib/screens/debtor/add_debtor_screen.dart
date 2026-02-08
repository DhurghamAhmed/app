import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/app_card.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../models/debtor_model.dart';
import '../../models/debt_item_model.dart';
import '../../models/transaction_model.dart';
import '../../services/debtor_service.dart';
import '../../services/transaction_service.dart';
import '../../providers/auth_provider.dart';

class AddDebtorScreen extends StatefulWidget {
  const AddDebtorScreen({super.key});

  @override
  State<AddDebtorScreen> createState() => _AddDebtorScreenState();
}

class _AddDebtorScreenState extends State<AddDebtorScreen> {
  final DebtorService _debtorService = DebtorService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Convert Arabic numerals to English numerals
  String _convertArabicToEnglishNumbers(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  /// Extract only digits (supports both Arabic and English numerals)
  String _extractDigits(String input) {
    final converted = _convertArabicToEnglishNumbers(input);
    return converted.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Format amount with thousand separators
  String _formatAmountWithCommas(double amount) {
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

  @override
  void dispose() {
    _searchController.dispose();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtorDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            Expanded(child: _buildDebtorsList(isDark, userId)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.people_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.debtors,
                      style: AppTextStyles.headingMedium()),
                  Text(context.l10n.manageYourDebtors,
                      style: AppTextStyles.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Field
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: AppTextStyles.bodyMedium(),
              decoration: InputDecoration(
                hintText: context.l10n.searchByName,
                hintStyle: AppTextStyles.bodyMedium(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtorsList(bool isDark, String? userId) {
    if (userId == null) {
      return Center(child: Text(context.l10n.translate('please_login')));
    }

    return StreamBuilder<List<DebtorModel>>(
      stream: _debtorService.streamDebtors(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDebtors = snapshot.data ?? [];

        // Filter by search query
        final debtors = _searchQuery.isEmpty
            ? allDebtors
            : allDebtors.where((debtor) {
                return debtor.name.toLowerCase().contains(_searchQuery);
              }).toList();

        if (allDebtors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.people_outline_rounded,
                      size: 50,
                      color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
                Text(context.l10n.translate('no_debtors_yet'),
                    style: AppTextStyles.headingSmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text(context.l10n.translate('tap_to_add_debtor'),
                    style: AppTextStyles.bodyMedium(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)),
              ],
            ),
          );
        }

        // No results from search
        if (debtors.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(Icons.search_off_rounded,
                      size: 40,
                      color: AppColors.warning.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 20),
                Text(context.l10n.translate('no_results_found'),
                    style: AppTextStyles.titleLarge(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text(
                    '${context.l10n.translate('no_debtor_matches')}: "$_searchQuery"',
                    style: AppTextStyles.bodyMedium(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPaddingHorizontal, vertical: 8),
          itemCount: debtors.length,
          itemBuilder: (context, index) {
            final debtor = debtors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DebtorCard(
                debtor: debtor,
                isDark: isDark,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DebtorDetailsScreen(debtor: debtor))),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDebtorDialog(BuildContext parentContext) {
    final nameController = TextEditingController();
    final productController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final authProvider = Provider.of<AuthProvider>(ctx, listen: false);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isLoading = false;
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Text(context.l10n.addNewDebtor,
                        style: AppTextStyles.headingSmall()),
                    const SizedBox(height: 8),
                    Text(context.l10n.translate('enter_debtor_details'),
                        style: AppTextStyles.bodySmall(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)),
                    const SizedBox(height: 24),
                    InputField(
                        label: context.l10n.debtorName,
                        hint: context.l10n.translate('enter_full_name'),
                        controller: nameController,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v?.isEmpty == true
                            ? context.l10n.translate('name_required')
                            : null),
                    const SizedBox(height: 16),
                    InputField(
                        label: context.l10n.product,
                        hint: context.l10n.translate('what_did_they_buy'),
                        controller: productController,
                        prefixIcon: Icons.shopping_bag_outlined,
                        validator: (v) => v?.isEmpty == true
                            ? context.l10n.translate('product_required')
                            : null),
                    const SizedBox(height: 16),
                    InputField(
                        label: context.l10n.amount,
                        hint: context.l10n.translate('enter_price'),
                        controller: amountController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final rawNumber = _extractDigits(value);
                          if (rawNumber.isNotEmpty) {
                            final formatted = _formatAmountWithCommas(
                                double.parse(rawNumber));
                            if (formatted != value) {
                              amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          }
                        },
                        validator: (v) {
                          if (v?.isEmpty == true)
                            return context.l10n.translate('amount_required');
                          final rawNumber = _extractDigits(v!);
                          if (rawNumber.isEmpty ||
                              double.tryParse(rawNumber) == null) {
                            return context.l10n.translate('invalid_amount');
                          }
                          return null;
                        }),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: context.l10n.translate('add_debtor'),
                      isLoading: isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => isLoading = true);
                        try {
                          final debtor = await _debtorService.addDebtor(
                              userId: authProvider.userId!,
                              name: nameController.text.trim(),
                              addedByUserName:
                                  authProvider.userModel?.fullName);
                          final rawAmount =
                              _extractDigits(amountController.text.trim());
                          await _debtorService.addDebtItem(
                              debtorId: debtor.id,
                              userId: authProvider.userId!,
                              product: productController.text.trim(),
                              amount: double.parse(rawAmount),
                              debtorName: debtor.name,
                              addedByUserName:
                                  authProvider.userModel?.fullName);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            // Show success notification
                            final locale =
                                Localizations.localeOf(parentContext);
                            final isArabic = locale.languageCode == 'ar';
                            final successMsg = isArabic
                                ? 'تمت إضافة المديون "${nameController.text.trim()}" بنجاح'
                                : 'Debtor "${nameController.text.trim()}" added successfully';

                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(successMsg)),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isLoading = false);
                          if (e.toString().contains('DEBTOR_EXISTS') &&
                              ctx.mounted) {
                            final debtorName = nameController.text.trim();
                            final locale = Localizations.localeOf(ctx);
                            final isArabic = locale.languageCode == 'ar';
                            final errorMsg = isArabic
                                ? 'يوجد مدين بهذا الاسم بالفعل!'
                                : 'A debtor with this name already exists!';
                            final okBtn = isArabic ? 'موافق' : 'OK';

                            showDialog(
                              context: ctx,
                              builder: (dialogCtx) {
                                final isDarkDialog =
                                    Theme.of(dialogCtx).brightness ==
                                        Brightness.dark;
                                return AlertDialog(
                                  backgroundColor: isDarkDialog
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  icon: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_off_rounded,
                                        color: AppColors.warning, size: 28),
                                  ),
                                  title: Text(
                                    errorMsg,
                                    style: AppTextStyles.titleMedium(),
                                    textAlign: TextAlign.center,
                                  ),
                                  content: Text(
                                    '"$debtorName"',
                                    style: AppTextStyles.bodyMedium(
                                      color: isDarkDialog
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      child: Text(okBtn),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }
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
}

class _DebtorCard extends StatelessWidget {
  final DebtorModel debtor;
  final bool isDark;
  final VoidCallback onTap;

  const _DebtorCard(
      {required this.debtor, required this.isDark, required this.onTap});

  /// Get dynamic color based on debt amount
  /// Red if >= 100,000, black otherwise
  Color _getDebtColor(double amount, bool isDark) {
    if (amount >= 100000) {
      return AppColors.error;
    }
    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  }

  /// Format amount with thousand separators (full number)
  String _formatFullAmount(double amount) {
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

  @override
  Widget build(BuildContext context) {
    final debtColor = _getDebtColor(debtor.amount, isDark);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Text(debtor.initials,
                    style: AppTextStyles.titleLarge(color: Colors.white))),
          ),
          const SizedBox(width: 12),
          // Name and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debtor.name,
                  style: AppTextStyles.titleMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Date only
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(debtor.createdAt),
                      style: AppTextStyles.caption(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'IQD ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: debtColor.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _formatFullAmount(debtor.amount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: debtColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight),
        ],
      ),
    );
  }
}

class DebtorDetailsScreen extends StatefulWidget {
  final DebtorModel debtor;
  const DebtorDetailsScreen({super.key, required this.debtor});

  @override
  State<DebtorDetailsScreen> createState() => _DebtorDetailsScreenState();
}

/// Static helper function to convert Arabic numerals to English
String _convertArabicToEnglishStatic(String input) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String result = input;
  for (int i = 0; i < arabic.length; i++) {
    result = result.replaceAll(arabic[i], english[i]);
  }
  return result;
}

/// Static helper function to extract digits (supports Arabic and English)
String _extractDigitsStatic(String input) {
  final converted = _convertArabicToEnglishStatic(input);
  return converted.replaceAll(RegExp(r'[^\d]'), '');
}

class _DebtorDetailsScreenState extends State<DebtorDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final DebtorService _debtorService = DebtorService();
  final TransactionService _transactionService = TransactionService();
  int _currentTabIndex = 0;
  int _previousItemCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Format amount with thousand separators (full number)
  String _formatFullAmount(double amount) {
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

  /// Format date to relative or absolute
  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return context.l10n.translate('today');
    } else if (difference == 1) {
      return context.l10n.translate('yesterday');
    } else if (difference < 7) {
      return '$difference ${context.l10n.translate('days_ago')}';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Get debt age color (newer = red, older = orange/warning)
  Color _getDebtAgeColor(DateTime createdAt) {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    if (daysSinceCreated <= 7) {
      return AppColors.error; // New debt - red
    } else if (daysSinceCreated <= 30) {
      return AppColors.warning; // Medium age - orange
    } else {
      return AppColors.debtMedium; // Old debt - softer orange
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Add Debt',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: StreamBuilder<List<DebtorModel>>(
        stream: _debtorService.streamDebtors(authProvider.userId ?? ''),
        builder: (context, snapshot) {
          final currentDebtor = snapshot.data
                  ?.where((d) => d.id == widget.debtor.id)
                  .firstOrNull ??
              widget.debtor;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                    onPressed: () => _showDeleteConfirmation(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                  child: Text(currentDebtor.initials,
                                      style: AppTextStyles.titleMedium(
                                          color: Colors.white))),
                            ),
                            const SizedBox(height: 6),
                            // Name
                            Text(currentDebtor.name,
                                style: AppTextStyles.headingSmall(
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            // Total Debt + Metadata in one row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  )),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Amount Section
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.l10n.translate('total_debt'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            'IQD ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          Text(
                                            _formatFullAmount(
                                                currentDebtor.amount),
                                            style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 30,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  // Metadata Section
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Items count
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${currentDebtor.itemCount} ${context.l10n.translate('items')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Added by
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            size: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            currentDebtor.addedByUserName ??
                                                context.l10n
                                                    .translate('unknown'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Date added
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(
                                                currentDebtor.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  child: Container(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          labelStyle: AppTextStyles.labelLarge(),
                          unselectedLabelStyle: AppTextStyles.labelMedium(),
                          splashBorderRadius: BorderRadius.circular(10),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 16,
                                    color: _currentTabIndex == 0
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(context.l10n.translate('debts')),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 16,
                                    color: _currentTabIndex == 1
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(context.l10n.history),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildDebtsTab(
                      currentDebtor, isDark, authProvider.userId!),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildTransactionsTab(
                      currentDebtor, isDark, authProvider.userId!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebtsTab(DebtorModel debtor, bool isDark, String userId) {
    return StreamBuilder<List<DebtItemModel>>(
      stream: _debtorService.streamDebtItems(debtor.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        // Check if new item was added for animation
        final bool hasNewItem = items.length > _previousItemCount;
        if (snapshot.connectionState == ConnectionState.active) {
          _previousItemCount = items.length;
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      size: 40,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight),
                ),
                const SizedBox(height: 16),
                Text(context.l10n.translate('no_debts'),
                    style: AppTextStyles.titleMedium(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text(context.l10n.translate('tap_add_debt'),
                    style: AppTextStyles.bodySmall(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final debtColor = _getDebtAgeColor(item.createdAt);
            final isNewItem = hasNewItem && index == 0;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: isNewItem ? 0.0 : 1.0, end: 1.0),
              duration: Duration(milliseconds: isNewItem ? 400 : 0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => _showDebtItemOptions(item, debtor, userId),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: debtColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.shopping_bag_outlined,
                            color: debtColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Middle Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              item.product,
                              style: AppTextStyles.titleMedium(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Metadata Row
                            Row(
                              children: [
                                // Date
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(item.createdAt, context),
                                  style: AppTextStyles.caption(
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                ),
                                // Separator
                                if (item.addedByUserName != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  // Added By
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.addedByUserName!,
                                      style: AppTextStyles.caption(
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                                  color: debtColor.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                _formatFullAmount(item.amount),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: debtColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildTransactionsTab(DebtorModel debtor, bool isDark, String userId) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionService.streamDebtorHistory(userId, debtor.id),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 64,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
                const SizedBox(height: 16),
                Text(context.l10n.translate('no_debtor_transactions'),
                    style: AppTextStyles.titleMedium(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isPayment = tx.type == TransactionType.payment;
            final isEdit = tx.type == TransactionType.edit;

            // Get icon and color based on type
            IconData icon;
            Color color;
            if (isPayment) {
              icon = Icons.check_circle_outline;
              color = AppColors.success;
            } else if (isEdit) {
              icon = Icons.edit_outlined;
              color = AppColors.warning;
            } else {
              icon = Icons.add_circle_outline;
              color = AppColors.error;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => _showTransactionDetails(tx, isDark),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_cleanDescription(tx.description, context),
                              style: AppTextStyles.titleSmall(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          // Performed By
                          if (tx.performedByUserName != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tx.performedByUserName!,
                                  style: AppTextStyles.caption(
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isEdit)
                              Text(
                                isPayment ? '+' : '-',
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
                              _formatFullAmount(tx.amount),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(DateFormat('MMM d').format(tx.date),
                            style: AppTextStyles.caption(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight)),
                      ],
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

  void _showTransactionDetails(TransactionModel tx, bool isDark) {
    final isPayment = tx.type == TransactionType.payment;
    final isEdit = tx.type == TransactionType.edit;

    // Determine icon, color, and title based on transaction type
    IconData icon;
    Color color;
    String title;
    String amountDisplay;

    if (isPayment) {
      icon = Icons.check_circle_outline;
      color = AppColors.success;
      title = context.l10n.translate('payment_received');
      amountDisplay = '+IQD ${_formatFullAmount(tx.amount)}';
    } else if (isEdit) {
      icon = Icons.edit_outlined;
      color = AppColors.warning;
      title = context.l10n.translate('price_updated');
      amountDisplay = 'IQD ${_formatFullAmount(tx.amount)}';
    } else {
      icon = Icons.add_circle_outline;
      color = AppColors.error;
      title = context.l10n.translate('debt_added');
      amountDisplay = '-IQD ${_formatFullAmount(tx.amount)}';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.headingSmall()),
              const SizedBox(height: 8),
              Text(amountDisplay,
                  style: AppTextStyles.displaySmall(color: color)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildDetailRow(context.l10n.translate('description'),
                        _cleanDescription(tx.description, context), isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        context.l10n.translate('date'),
                        DateFormat('EEEE, MMMM d, yyyy').format(tx.date),
                        isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow(context.l10n.translate('time'),
                        DateFormat('h:mm a').format(tx.date), isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow(context.l10n.translate('type'),
                        tx.typeDisplayName, isDark),
                    if (tx.performedByUserName != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(context.l10n.translate('performed_by'),
                          tx.performedByUserName!, isDark),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.l10n.close))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight)),
        Flexible(
            child: Text(value,
                style: AppTextStyles.titleSmall(), textAlign: TextAlign.end)),
      ],
    );
  }

  /// Clean description - remove person name, keep only product/action
  String _cleanDescription(String? description, BuildContext context) {
    if (description == null || description.isEmpty) {
      return context.l10n.translate('no_description');
    }

    // Remove " - PersonName" pattern at the end
    // Examples: "iPhone - Ahmed" → "iPhone"
    //           "Settled: Laptop - Hassan" → "Settled: Laptop"
    final parts = description.split(' - ');
    if (parts.length > 1) {
      // Remove the last part (person name)
      parts.removeLast();
      return parts.join(' - ');
    }

    return description;
  }

  void _showAddDebtDialog() {
    final productController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final authProvider = Provider.of<AuthProvider>(ctx, listen: false);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isLoading = false;
            return Container(
              decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Text(context.l10n.translate('add_debt'),
                        style: AppTextStyles.headingSmall()),
                    Text(
                        '${context.l10n.translate('for_debtor')} ${widget.debtor.name}',
                        style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)),
                    const SizedBox(height: 24),
                    InputField(
                        label: context.l10n.product,
                        hint: context.l10n.translate('what_did_they_buy'),
                        controller: productController,
                        prefixIcon: Icons.shopping_bag_outlined,
                        validator: (v) => v?.isEmpty == true
                            ? context.l10n.translate('required')
                            : null),
                    const SizedBox(height: 16),
                    InputField(
                        label: context.l10n.amount,
                        hint: context.l10n.translate('enter_price'),
                        controller: amountController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final rawNumber = _extractDigitsStatic(value);
                          if (rawNumber.isNotEmpty) {
                            final formatted =
                                _formatFullAmount(double.parse(rawNumber));
                            if (formatted != value) {
                              amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          }
                        },
                        validator: (v) {
                          if (v?.isEmpty == true)
                            return context.l10n.translate('required');
                          final rawNumber = _extractDigitsStatic(v!);
                          if (rawNumber.isEmpty ||
                              double.tryParse(rawNumber) == null) {
                            return context.l10n.translate('invalid');
                          }
                          return null;
                        }),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: context.l10n.translate('add_debt'),
                      isLoading: isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => isLoading = true);
                        try {
                          final rawDebtAmount = _extractDigitsStatic(
                              amountController.text.trim());
                          await _debtorService.addDebtItem(
                              debtorId: widget.debtor.id,
                              userId: authProvider.userId!,
                              product: productController.text.trim(),
                              amount: double.parse(rawDebtAmount),
                              debtorName: widget.debtor.name,
                              addedByUserName:
                                  authProvider.userModel?.fullName);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setModalState(() => isLoading = false);
                        }
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

  void _showDebtItemOptions(
      DebtItemModel item, DebtorModel debtor, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.error)),
              const SizedBox(height: 16),
              Text(item.product, style: AppTextStyles.headingSmall()),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'IQD ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _formatFullAmount(item.amount),
                    style: AppTextStyles.titleLarge(color: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                  text: context.l10n.translate('settle_mark_paid'),
                  backgroundColor: AppColors.success,
                  leadingIcon: Icons.check_rounded,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final debtorDeleted = await _debtorService.settleDebtItem(
                      itemId: item.id,
                      debtorId: debtor.id,
                      userId: userId,
                      debtorName: debtor.name,
                      product: item.product,
                      amount: item.amount,
                      performedByUserName:
                          Provider.of<AuthProvider>(context, listen: false)
                              .userModel
                              ?.fullName,
                    );
                    // If debtor was deleted (no more debts), go back to debtors list
                    if (debtorDeleted) {
                      if (!context.mounted) return;
                      final currentContext = context;
                      Navigator.pop(currentContext);
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${debtor.name} has been fully settled and removed'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  }),
              const SizedBox(height: 12),
              PrimaryButton(
                  text: context.l10n.translate('edit_amount'),
                  variant: ButtonVariant.outlined,
                  leadingIcon: Icons.attach_money,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditDebtDialog(item, debtor, userId);
                  }),
              const SizedBox(height: 12),
              PrimaryButton(
                  text: context.l10n.translate('edit_product_name'),
                  variant: ButtonVariant.outlined,
                  leadingIcon: Icons.edit_outlined,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditProductDialog(item, debtor, userId);
                  }),
              const SizedBox(height: 12),
              PrimaryButton(
                  text: context.l10n.translate('delete_debt'),
                  variant: ButtonVariant.outlined,
                  leadingIcon: Icons.delete_outline_rounded,
                  foregroundColor: AppColors.error,
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeleteDebtConfirmation(item, debtor, userId);
                  }),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDebtConfirmation(
      DebtItemModel item, DebtorModel debtor, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text(context.l10n.translate('delete_debt_title'),
                  style: AppTextStyles.headingSmall()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.translate('delete_debt_confirm'),
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
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product, style: AppTextStyles.titleSmall()),
                          Text('IQD ${_formatFullAmount(item.amount)}',
                              style: AppTextStyles.caption(
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.translate('action_cannot_undo'),
                style: AppTextStyles.caption(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteDebtItem(item, debtor, userId);
              },
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDebtItem(
      DebtItemModel item, DebtorModel debtor, String userId) async {
    try {
      final debtorDeleted = await _debtorService.deleteDebtItem(
        itemId: item.id,
        debtorId: debtor.id,
        userId: userId,
        debtorName: debtor.name,
        product: item.product,
        amount: item.amount,
      );

      if (!mounted) return;

      if (debtorDeleted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${debtor.name} has been removed (no more debts)'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.product}" has been deleted'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting debt: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showEditProductDialog(
      DebtItemModel item, DebtorModel debtor, String userId) {
    final productController = TextEditingController(text: item.product);
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isLoading = false;
            return Container(
              decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Text(context.l10n.translate('edit_product_name_title'),
                        style: AppTextStyles.headingSmall()),
                    Text('IQD ${_formatFullAmount(item.amount)}',
                        style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)),
                    const SizedBox(height: 24),
                    InputField(
                        label: context.l10n.translate('product_name'),
                        hint: context.l10n.translate('enter_new_product_name'),
                        controller: productController,
                        prefixIcon: Icons.shopping_bag_outlined,
                        validator: (v) => v?.isEmpty == true
                            ? context.l10n.translate('required')
                            : null),
                    const SizedBox(height: 24),
                    PrimaryButton(
                        text: context.l10n.save,
                        isLoading: isLoading,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final newProduct = productController.text.trim();
                          if (newProduct == item.product) {
                            Navigator.pop(ctx);
                            return;
                          }
                          setModalState(() => isLoading = true);
                          try {
                            await _debtorService.updateDebtItemProduct(
                              itemId: item.id,
                              debtorId: debtor.id,
                              userId: userId,
                              debtorName: debtor.name,
                              oldProduct: item.product,
                              newProduct: newProduct,
                              amount: item.amount,
                              performedByUserName: Provider.of<AuthProvider>(
                                      context,
                                      listen: false)
                                  .userModel
                                  ?.fullName,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setModalState(() => isLoading = false);
                          }
                        }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDebtDialog(
      DebtItemModel item, DebtorModel debtor, String userId) {
    final amountController =
        TextEditingController(text: _formatFullAmount(item.amount));
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isLoading = false;
            return Container(
              decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Text(context.l10n.translate('edit_amount_title'),
                        style: AppTextStyles.headingSmall()),
                    Text(item.product,
                        style: AppTextStyles.bodyMedium(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight)),
                    const SizedBox(height: 24),
                    InputField(
                        label: context.l10n.amount,
                        controller: amountController,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // Format with thousand separators as user types
                          final rawNumber = _extractDigitsStatic(value);
                          if (rawNumber.isNotEmpty) {
                            final formatted =
                                _formatFullAmount(double.parse(rawNumber));
                            if (formatted != value) {
                              amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          }
                        },
                        validator: (v) {
                          if (v?.isEmpty == true)
                            return context.l10n.translate('required');
                          final rawNumber = _extractDigitsStatic(v!);
                          if (rawNumber.isEmpty ||
                              double.tryParse(rawNumber) == null) {
                            return context.l10n.translate('invalid');
                          }
                          return null;
                        }),
                    const SizedBox(height: 24),
                    PrimaryButton(
                        text: context.l10n.save,
                        isLoading: isLoading,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final rawNumber = _extractDigitsStatic(
                              amountController.text.trim());
                          final newAmount = double.tryParse(rawNumber);
                          if (newAmount == null) return;
                          setModalState(() => isLoading = true);
                          try {
                            await _debtorService.updateDebtItem(
                              itemId: item.id,
                              debtorId: debtor.id,
                              userId: userId,
                              debtorName: debtor.name,
                              product: item.product,
                              oldAmount: item.amount,
                              newAmount: newAmount,
                              performedByUserName: Provider.of<AuthProvider>(
                                      context,
                                      listen: false)
                                  .userModel
                                  ?.fullName,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setModalState(() => isLoading = false);
                          }
                        }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.l10n.translate('delete_debtor'),
              style: AppTextStyles.headingSmall()),
          content: Text(context.l10n.translate('delete_debtor_confirm'),
              style: AppTextStyles.bodyMedium()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(ctx);
                await _debtorService.deleteDebtor(widget.debtor.id);
                if (mounted) Navigator.pop(context);
              },
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 58;

  @override
  double get minExtent => 58;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
