import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display Styles
  static TextStyle displayLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle displayMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle displaySmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  // Heading Styles
  static TextStyle headingLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle headingMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle headingSmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  // Title Styles
  static TextStyle titleLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle titleMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle titleSmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  // Body Styles
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
    color: color ?? AppColors.textSecondaryLight,
  );
  
  static TextStyle bodySmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
    color: color ?? AppColors.textTertiaryLight,
  );
  
  // Label Styles
  static TextStyle labelLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle labelMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color ?? AppColors.textSecondaryLight,
  );
  
  static TextStyle labelSmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: color ?? AppColors.textTertiaryLight,
  );
  
  // Button Styles
  static TextStyle buttonLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: color ?? Colors.white,
  );
  
  static TextStyle buttonMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: color ?? Colors.white,
  );
  
  static TextStyle buttonSmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: color ?? Colors.white,
  );
  
  // Caption & Overline
  static TextStyle caption({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: color ?? AppColors.textTertiaryLight,
  );
  
  static TextStyle overline({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: color ?? AppColors.textTertiaryLight,
  );
  
  // Number Styles (for KPIs and stats)
  static TextStyle numberLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle numberMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: color ?? AppColors.textPrimaryLight,
  );
  
  static TextStyle numberSmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color ?? AppColors.textPrimaryLight,
  );
}
