import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Tema unificado de TicketPotosí.
/// Soporta Dark Mode (principal) y Light Mode.
class AppTheme {
  AppTheme._();

  // ─── DARK THEME (Principal) ──────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: AppDimensions.fontXl,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: AppDimensions.fontLg,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, color: AppColors.textPrimary),
      displayMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    ),
  );

  // ─── LIGHT THEME ─────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: AppDimensions.fontXl,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: const BorderSide(color: AppColors.cardBorderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: AppDimensions.fontLg,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.cardBorderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.cardBorderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textMutedLight),
      labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, color: AppColors.textPrimaryLight),
      displayMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight),
      headlineLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
      headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
      titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, color: AppColors.textSecondaryLight),
      labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
    ),
  );
}
