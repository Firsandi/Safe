import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static TextStyle subHeading = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
    height: 1.5,
  );

  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textGrey,
    letterSpacing: 1.2,
  );

  static TextStyle buttonPrimary = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.0,
  );

  static TextStyle buttonSecondary = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: 0.5,
  );

  static TextStyle footer = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inputIconGrey,
    letterSpacing: 0.8,
  );
}
