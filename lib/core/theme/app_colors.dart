import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Professional Dark Slate (POS System)
  static const Color primary =
      Color(0xFF1E293B); // Slate 800 - Professional dark
  static const Color primaryLight = Color(0xFF334155); // Slate 700
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900

  // Secondary Colors - Business Blue
  static const Color secondary =
      Color(0xFF0EA5E9); // Sky 500 - Professional blue
  static const Color secondaryLight = Color(0xFF38BDF8); // Sky 400
  static const Color secondaryDark = Color(0xFF0284C7); // Sky 600

  // Accent Colors - Removed playful colors, kept professional tones
  static const Color accentOrange =
      Color(0xFFF59E0B); // Amber 500 - Warning/Alert
  static const Color accentBlue = Color(0xFF3B82F6); // Blue 500 - Info

  // Neutral Colors - Light Theme (Clean & Professional)
  static const Color backgroundLight =
      Color(0xFFF8FAFC); // Slate 50 - Very light gray
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure white
  static const Color cardLight = Color(0xFFFFFFFF); // Pure white cards
  static const Color textPrimaryLight =
      Color(0xFF0F172A); // Slate 900 - Dark text
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textTertiaryLight = Color(0xFF94A3B8); // Slate 400
  static const Color dividerLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Neutral Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiaryDark = Color(0xFF64748B); // Slate 500
  static const Color dividerDark = Color(0xFF334155); // Slate 700
  static const Color borderDark = Color(0xFF334155); // Slate 700

  // Status Colors - Financial/Accounting focused
  static const Color success = Color(0xFF16A34A); // Green 600 - Sales/Profit
  static const Color warning = Color(0xFFF59E0B); // Amber 500 - Warnings
  static const Color error = Color(0xFFDC2626); // Red 600 - Debt/Loss
  static const Color info = Color(0xFF0EA5E9); // Sky 500 - Information

  // Financial Status Colors (Specific for POS)
  static const Color profit = Color(0xFF16A34A); // Green - Positive balance
  static const Color debt = Color(0xFFDC2626); // Red - Negative balance
  static const Color pending =
      Color(0xFFF59E0B); // Amber - Pending transactions

  // Dynamic Status Colors for Financial Data
  static const Color salesAmount = Color(0xFF16A34A); // Green for sales
  static const Color debtAmount = Color(0xFFDC2626); // Red for debts
  static const Color debtMedium = Color(0xFFF59E0B); // Orange for medium debt
  static const Color paymentAmount =
      Color(0xFF22C55E); // Soft green for payments
  static const Color openListIndicator =
      Color(0xFF1E40AF); // Dark blue for open lists
  static const Color closedListIndicator =
      Color(0xFF6B7280); // Neutral grey for closed lists
  static const Color activeSalesBanner =
      Color(0xFFDCFCE7); // Soft green background
  static const Color activeSalesBannerDark =
      Color(0xFF14532D); // Dark mode soft green

  // Dynamic color helper for debt amounts
  static Color getDebtColor(double amount) {
    if (amount <= 0) return success;
    if (amount < 100000) return debtMedium; // Medium debt (orange)
    return debtAmount; // High debt (red)
  }

  // Dynamic color helper for sales amounts
  static Color getSalesColor(double amount) {
    if (amount <= 0) return textTertiaryLight;
    return salesAmount; // Green for positive sales
  }

  // Dynamic color helper for payment amounts
  static Color getPaymentColor() {
    return paymentAmount; // Soft green for payments
  }

  // Dynamic color helper for list status
  static Color getListStatusColor(bool isOpen) {
    return isOpen ? openListIndicator : closedListIndicator;
  }

  // Gradient Colors - Minimal, professional gradients only
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF334155)], // Subtle dark gradient
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)], // Green gradient for sales
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red gradient for debts
  );

  // Shadow Colors - Lighter, more subtle
  static Color shadowLight = Colors.black.withValues(alpha: 0.04);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.06);
  static Color shadowDark = Colors.black.withValues(alpha: 0.08);

  // Card Shadows - Reduced for cleaner look
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Button Shadows - Subtle elevation
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
