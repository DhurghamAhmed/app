import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'app_card.dart';
import 'progress_ring.dart';

/// Enum for KPI card status types - determines dynamic coloring
enum KpiStatusType {
  sales, // Green - for sales amounts
  debt, // Red - for debt amounts
  payment, // Soft green - for payments
  neutral, // Default theme colors
  warning, // Orange - for medium priority
}

/// Helper class for currency formatting
class CurrencyFormatter {
  /// Formats amount with IQD currency in professional style
  /// Returns a widget with smaller currency label and bold amount
  static Widget formatIQD(
    double amount, {
    Color? color,
    double amountFontSize = 24,
    double currencyFontSize = 12,
    FontWeight amountWeight = FontWeight.w700,
  }) {
    final formattedAmount = NumberFormat('#,###').format(amount.abs());
    final displayColor = color ?? AppColors.textPrimaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'IQD ',
          style: TextStyle(
            fontSize: currencyFontSize,
            fontWeight: FontWeight.w500,
            color: displayColor.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        Text(
          formattedAmount,
          style: TextStyle(
            fontSize: amountFontSize,
            fontWeight: amountWeight,
            color: displayColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  /// Gets dynamic color based on debt amount
  static Color getDebtStatusColor(double amount) {
    return AppColors.getDebtColor(amount);
  }

  /// Gets dynamic color based on sales amount
  static Color getSalesStatusColor(double amount) {
    return AppColors.getSalesColor(amount);
  }
}

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;
  final bool trendUp;
  final KpiStatusType statusType;
  final Color? valueColor;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.gradient,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
    this.trendUp = true,
    this.statusType = KpiStatusType.neutral,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    if (gradient != null) {
      return GradientCard(
        gradient: gradient!,
        onTap: onTap,
        child: _buildContent(context, isGradient: true),
      );
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: _buildContent(context, isGradient: false),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isGradient}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isGradient ? Colors.white : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon and Trend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : (iconBackgroundColor ??
                          AppColors.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isGradient
                      ? Colors.white
                      : (iconColor ?? AppColors.primary),
                ),
              ),
            if (showTrend && trendValue != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (trendUp ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: trendUp ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trendValue!.toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall(
                        color: trendUp ? AppColors.success : AppColors.error,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Value - Large and prominent
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textColor ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        // Title
        Text(
          title,
          style: AppTextStyles.bodyMedium(
            color: isGradient
                ? Colors.white.withValues(alpha: 0.9)
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AppTextStyles.caption(
              color: isGradient
                  ? Colors.white.withValues(alpha: 0.7)
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
            ),
          ),
        ],
      ],
    );
  }
}

// KPI Card with Progress Ring
class KpiProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final Color? progressColor;
  final Color? backgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const KpiProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    this.progressColor,
    this.backgroundColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 70,
            strokeWidth: 8,
            progressColor: progressColor ?? AppColors.primary,
            backgroundColor: backgroundColor ??
                (isDark ? AppColors.borderDark : AppColors.borderLight),
            child: Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyles.titleMedium(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.numberMedium(),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Compact KPI Card
class KpiCardCompact extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const KpiCardCompact({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? AppColors.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: cardColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleLarge(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
