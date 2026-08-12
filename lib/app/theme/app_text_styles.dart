import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text style constants used throughout the app
class AppTextStyles {
  AppTextStyles._();

  // Headers
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // Body
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // Labels
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Monospace — for chemical formulas and values
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Splash screen
  static TextStyle get splashTitle => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
      );

  static TextStyle get splashSubtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
      );

  // Chemical formula subscript
  static TextStyle get formulaBase => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get formulaSubscript => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
}
