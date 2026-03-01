import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette - warm teal for trust and care
  static const Color primary = Color(0xFF2A9D8F);
  static const Color primaryLight = Color(0xFF5EC4B6);
  static const Color primaryDark = Color(0xFF1A7A6E);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary palette - soft coral for warmth
  static const Color secondary = Color(0xFFE76F51);
  static const Color secondaryLight = Color(0xFFF4A261);
  static const Color secondaryDark = Color(0xFFC4533A);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Tertiary - soft blue for informational
  static const Color tertiary = Color(0xFF457B9D);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // Neutral palette
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF42A5F5);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2F5);
  static const Color onBackgroundLight = Color(0xFF1A1C1E);
  static const Color onSurfaceLight = Color(0xFF1A1C1E);
  static const Color onSurfaceVariantLight = Color(0xFF44474E);
  static const Color outlineLight = Color(0xFFE0E3E8);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color onBackgroundDark = Color(0xFFE3E3E3);
  static const Color onSurfaceDark = Color(0xFFE3E3E3);
  static const Color onSurfaceVariantDark = Color(0xFFC4C6CF);
  static const Color outlineDark = Color(0xFF3A3A3A);
}
