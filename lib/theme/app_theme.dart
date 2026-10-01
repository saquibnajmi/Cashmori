import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Central place for all colors / text styles so every screen looks
/// consistent and matches the original mockup:
/// light grey background, white rounded cards, soft shadow, yellow accent,
/// red for expense, green for income.
class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF5D67A); // yellow "SAVE" button
  static const accentDark = Color(0xFFE0B84D);
  static const expense = Color(0xFFD32F2F);
  static const income = Color(0xFF2E9E44);
  static const textPrimary = Color(0xFF3A3A3A);
  static const textSecondary = Color(0xFF7A7A7A);
  static const divider = Color(0xFFDADADA);
}

class MoneyFormatter {
  static final NumberFormat _full = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _compact = NumberFormat('#,##,##0.##', 'en_IN');

  static String format(double value,
      {bool withDecimal = true, bool showSign = false}) {
    final absolute = value.abs();
    final formatted =
        withDecimal ? _full.format(absolute) : _compact.format(absolute);

    if (value == 0) return withDecimal ? '0.00' : '0';
    if (!showSign) return formatted;
    return value > 0 ? '+$formatted' : '-$formatted';
  }
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentDark,
        primary: AppColors.accentDark,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        errorStyle: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
