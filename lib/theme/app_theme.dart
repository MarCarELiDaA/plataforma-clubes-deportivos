import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF071A42); // Color mejorado #071A42
  static const Color primaryLight = Color(0xFF071A42);
  static const Color accentGreen = Color(0xFF50C878);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color accentWhite = Color(0xFFFFFFFF);
  static const Color accentGrey = Color(0xFF6B7B8C);
  static const Color backgroundDark = Color(0xFF071A42); // Fondo mejorado
  static const Color cardBackground = Color(0xFF071A42);
  static const Color errorRed = Color(0xFFE53935);
  static const Color maintenanceBrown = Color(0xFF8B4513);
  static const Color destructiveRed = Color(0xFFDC143C); // Rojo oscuro compatible para acciones destructivas

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        primaryContainer: primaryLight,
        secondary: accentGreen,
        secondaryContainer: accentYellow,
        tertiary: accentWhite,
        surface: cardBackground,
        error: errorRed,
        onPrimary: accentWhite,
        onSecondary: Colors.white,
        onTertiary: primaryBlue,
        onSurface: accentWhite,
        onError: Colors.white,
        surfaceContainer: primaryBlue,
        onSurfaceVariant: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: accentGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: accentYellow),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical:16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accentGreen,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentGreen,
          side: const BorderSide(color: accentGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGreen,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8), 
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Colors.black),
        floatingLabelStyle: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
        errorStyle: const TextStyle(color: errorRed),
        prefixIconColor: accentGreen,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white.withValues(alpha: 0.9),
      ),
      iconTheme: const IconThemeData(
        color: Colors.black,
        size: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryBlue,
        contentTextStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: accentGreen,
        headerBackgroundColor: primaryBlue,
        headerForegroundColor: Colors.white,
        weekdayStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        dayStyle: const TextStyle(color: Colors.white),
        dayForegroundColor: WidgetStateProperty.all(Colors.white),
        todayBackgroundColor: WidgetStateProperty.all(Colors.white),
        todayForegroundColor: WidgetStateProperty.all(accentGreen),
        rangePickerBackgroundColor: accentGreen,
        rangePickerHeaderBackgroundColor: primaryBlue,
        rangePickerHeaderForegroundColor: Colors.white,
        yearBackgroundColor: WidgetStateProperty.all(accentGreen),
        yearForegroundColor: WidgetStateProperty.all(Colors.white),
        rangeSelectionBackgroundColor: primaryBlue,
        rangeSelectionOverlayColor: WidgetStateProperty.all(Colors.white),
        confirmButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(primaryBlue),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          textStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        cancelButtonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          foregroundColor: WidgetStateProperty.all(accentGreen),
          textStyle: WidgetStateProperty.all(
            const TextStyle(color: accentGreen, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),

    );
  }
}
