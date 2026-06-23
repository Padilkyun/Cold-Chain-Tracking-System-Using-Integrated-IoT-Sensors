import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A9B6C);
  static const Color primaryLight = Color(0xFF2DBF87);
  static const Color background = Color(0xFFF7F8FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF888888);
  static const Color textMedium = Color(0xFF444444);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color inputBorder = Color(0xFF1A9B6C);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      );
}
