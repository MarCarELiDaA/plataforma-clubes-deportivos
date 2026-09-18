import 'package:flutter/material.dart';

import '../config/app_config.dart';

class AppTheme {
  // ============================================================
  // CONVERSIÓN DE COLORES DEL CLUB
  // ============================================================

  static Color _colorDesdeHex(String hex) {
    final valor = hex.replaceAll('#', '').trim();

    if (valor.length == 6) {
      return Color(int.parse('FF$valor', radix: 16));
    }

    if (valor.length == 8) {
      return Color(int.parse(valor, radix: 16));
    }

    return const Color(0xFF071A42);
  }

  // ============================================================
  // COLORES DE IDENTIDAD DEL CLUB
  // ============================================================

  static Color get primary => _colorDesdeHex(AppConfig.club.colorPrimario);

  static Color get primaryLight =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.08), primary);

  static Color get primaryDark =>
      Color.alphaBlend(Colors.black.withValues(alpha: 0.20), primary);

  static Color get secondary => _colorDesdeHex(AppConfig.club.colorSecundario);

  static Color get secondaryLight =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.12), secondary);

  static Color get accent => _colorDesdeHex(AppConfig.club.colorAcento);

  static Color get accentLight =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.16), accent);

  // ============================================================
  // COLORES FUNCIONALES
  // ============================================================

  static Color get success => secondary;

  static Color get successLight =>
      Color.alphaBlend(secondary.withValues(alpha: 0.12), clubSurface);

  static Color get warning => accent;

  static Color get warningLight =>
      Color.alphaBlend(accent.withValues(alpha: 0.12), clubSurface);

  static const Color error = Color(0xFFE53935);

  static Color get errorLight =>
      Color.alphaBlend(error.withValues(alpha: 0.12), clubSurface);

  // Alias de compatibilidad
  static Color get accentGreen => secondary;
  static Color get accentYellow => accent;
  static const Color errorRed = error;
  static const Color destructiveRed = error;

  // ============================================================
  // COLORES DINÁMICOS PERSONALIZABLES DEL CLUB
  // ============================================================

  static Color get clubBackground => _colorDesdeHex(AppConfig.club.colorFondo);

  static Color get clubSurface =>
      _colorDesdeHex(AppConfig.club.colorSuperficie);

  static Color get clubSurfaceSoft =>
      _colorDesdeHex(AppConfig.club.colorSuperficieAlternativa);

  static Color get clubSurfaceMuted =>
      Color.alphaBlend(const Color(0x14000000), clubSurfaceSoft);

  static Color get clubTextPrimary =>
      _colorDesdeHex(AppConfig.club.colorTextoPrincipal);

  static Color get clubTextSecondary =>
      _colorDesdeHex(AppConfig.club.colorTextoSecundario);

  static Color get clubTextTertiary =>
      Color.alphaBlend(clubTextSecondary.withValues(alpha: 0.70), clubSurface);

  static Color get clubBorder => _colorDesdeHex(AppConfig.club.colorBorde);

  static Color get clubBorderSoft =>
      Color.alphaBlend(clubBorder.withValues(alpha: 0.55), clubSurface);

  // ============================================================
  // CONTRASTE AUTOMÁTICO SOBRE COLORES
  // ============================================================

  static Color textoSobreColor(Color fondo) {
    return fondo.computeLuminance() > 0.45 ? Colors.black : Colors.white;
  }

  static Color get textOnPrimary => textoSobreColor(primary);

  static Color get textOnSecondary => textoSobreColor(secondary);

  static Color get textOnAccent => textoSobreColor(accent);

  // ============================================================
  // COLORES CONSTANTES DE COMPATIBILIDAD
  // ============================================================
  //
  // Se mantienen const porque existen widgets del proyecto
  // que utilizan estos colores dentro de constructores const.
  //
  // Los nuevos diseños deben utilizar los colores dinámicos
  // clubBackground, clubSurface, clubTextPrimary, etc.

  static const Color background = Color(0xFFF7F9FC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceSoft = Color(0xFFF1F5F9);

  static const Color surfaceMuted = Color(0xFFE8EDF3);

  static const Color textPrimary = Color(0xFF102033);

  static const Color textSecondary = Color(0xFF526274);

  static const Color textTertiary = Color(0xFF7C8A99);

  static const Color textOnColor = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFD7DEE7);

  static const Color borderSoft = Color(0xFFE8EDF3);

  // ============================================================
  // ALIASES DE COMPATIBILIDAD
  // ============================================================

  static Color get primaryBlue => primary;

  static const Color backgroundDark = background;

  static const Color accentWhite = Colors.white;

  static const Color cardBackground = surface;

  // ============================================================
  // SOMBRAS
  // ============================================================

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================================
  // TEMA PRINCIPAL
  // ============================================================

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      error: error,
      surface: clubSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: clubBackground,

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: secondary,
        selectionColor: secondaryLight,
        selectionHandleColor: secondary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: clubSurface,
        foregroundColor: clubTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: clubTextPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: clubTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: clubTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
        ),
        displaySmall: TextStyle(
          color: clubTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: clubTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: clubTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: clubTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: clubTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: clubTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: secondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: clubTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: clubTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: clubTextTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textOnSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: secondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: secondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: clubSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: clubBorderSoft, width: 1),
        ),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: secondaryLight,
        textColor: clubTextPrimary,
        iconColor: secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: textOnSecondary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: secondary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: clubSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: secondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: secondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: clubTextTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: TextStyle(color: clubTextTertiary, fontSize: 12),
        errorStyle: const TextStyle(
          color: error,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: secondary,
        suffixIconColor: secondary,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: clubBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: clubBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: secondary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: error, width: 1.2),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: secondary, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary;
          }

          return clubSurface;
        }),
        checkColor: WidgetStateProperty.all(textOnSecondary),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary;
          }

          return clubTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryLight;
          }

          return clubSurfaceMuted;
        }),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary;
          }

          return clubTextTertiary;
        }),
      ),

      dividerTheme: DividerThemeData(
        color: clubBorderSoft,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: TextStyle(color: textOnPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: clubSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: TextStyle(
          color: clubTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: clubTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: clubSurface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primary,
        headerForegroundColor: textOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        todayBackgroundColor: WidgetStateProperty.all(secondaryLight),
        todayForegroundColor: WidgetStateProperty.all(secondary),
        dayForegroundColor: WidgetStateProperty.all(clubTextPrimary),
        yearForegroundColor: WidgetStateProperty.all(clubTextPrimary),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: clubSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: clubSurface,
        modalBarrierColor: const Color(0x33000000),
        elevation: 8,
        showDragHandle: true,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: textOnPrimary, fontSize: 12),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: secondary,
        linearTrackColor: secondaryLight,
        circularTrackColor: clubSurfaceMuted,
      ),

      iconTheme: IconThemeData(color: secondary, size: 24),

      tabBarTheme: TabBarThemeData(
        labelColor: secondary,
        unselectedLabelColor: clubTextSecondary,
        indicatorColor: accent,
        dividerColor: clubBorderSoft,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: textOnSecondary,
        elevation: 2,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: clubSurface,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: clubBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: clubBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: secondary, width: 1.5),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(clubSurface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEMA OSCURO DE COMPATIBILIDAD
  // ============================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        error: error,
        surface: clubSurface,
      ),
    );
  }
}
