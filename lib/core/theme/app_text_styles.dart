import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared text styles used across the PreinspectionAgent flow.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle error = TextStyle(
    fontSize: 12,
    color: AppColors.textRed,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );
}
