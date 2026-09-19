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
  // COLORES BASE CONFIGURABLES DEL CLUB
  // ============================================================

  static Color get primary => _colorDesdeHex(AppConfig.club.colorPrimario);

  static Color get secondary => _colorDesdeHex(AppConfig.club.colorSecundario);

  static Color get accent => _colorDesdeHex(AppConfig.club.colorAcento);

  static Color get clubBackground => _colorDesdeHex(AppConfig.club.colorFondo);

  static Color get clubSurface =>
      _colorDesdeHex(AppConfig.club.colorSuperficie);

  static Color get clubSurfaceSoft =>
      _colorDesdeHex(AppConfig.club.colorSuperficieAlternativa);

  static Color get clubTextPrimary =>
      _colorDesdeHex(AppConfig.club.colorTextoPrincipal);

  static Color get clubTextSecondary =>
      _colorDesdeHex(AppConfig.club.colorTextoSecundario);

  static Color get clubBorder => _colorDesdeHex(AppConfig.club.colorBorde);

  // ============================================================
  // COLORES DERIVADOS DEL TEMA
  // ============================================================

  static Color get clubSurfaceMuted =>
      Color.alphaBlend(const Color(0x14000000), clubSurfaceSoft);

  static Color get clubTextTertiary =>
      Color.alphaBlend(clubTextSecondary.withValues(alpha: 0.70), clubSurface);

  static Color get clubBorderSoft =>
      Color.alphaBlend(clubBorder.withValues(alpha: 0.55), clubSurface);

  // ============================================================
  // COLORES SEMÁNTICOS
  // ============================================================
  //
  // Las pantallas nuevas deberían utilizar preferentemente
  // estos nombres en lugar de saber qué color concreto utiliza
  // cada club.
  // ============================================================

  /// Color principal de identidad del club.
  static Color get identity => primary;

  /// Color destinado a acciones principales y controles.
  static Color get action => secondary;

  /// Color de acento visual.
  static Color get accentColor => accent;

  /// Fondo general de las pantallas.
  static Color get pageBackground => clubBackground;

  /// Superficie principal para tarjetas, formularios y paneles.
  static Color get surfaceColor => clubSurface;

  /// Superficie secundaria para bloques diferenciados.
  static Color get surfaceSoftColor => clubSurfaceSoft;

  /// Texto principal.
  static Color get textPrimaryColor => clubTextPrimary;

  /// Texto secundario.
  static Color get textSecondaryColor => clubTextSecondary;

  /// Texto terciario.
  static Color get textTertiaryColor => clubTextTertiary;

  /// Borde principal.
  static Color get borderColor => clubBorder;

  /// Borde suave.
  static Color get borderSoftColor => clubBorderSoft;

  // ============================================================
  // VARIANTES DE COLORES
  // ============================================================

  static Color get primaryLight =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.08), primary);

  static Color get primaryDark =>
      Color.alphaBlend(Colors.black.withValues(alpha: 0.20), primary);

  static Color get secondaryLight =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.12), secondary);

  static Color get accentLight =>
      Color.alphaBlend(Colors.white.withValues(alpha: 0.16), accent);

  static Color get actionLight =>
      Color.alphaBlend(action.withValues(alpha: 0.12), surfaceColor);

  static Color get identityLight =>
      Color.alphaBlend(identity.withValues(alpha: 0.08), surfaceColor);

  static Color get surfaceMuted => clubSurfaceMuted;

  // ============================================================
  // COLORES FUNCIONALES
  // ============================================================

  static Color get success => action;

  static Color get successLight =>
      Color.alphaBlend(action.withValues(alpha: 0.12), surfaceColor);

  static Color get warning => accentColor;

  static Color get warningLight =>
      Color.alphaBlend(accentColor.withValues(alpha: 0.12), surfaceColor);

  static const Color error = Color(0xFFE53935);

  static Color get errorLight =>
      Color.alphaBlend(error.withValues(alpha: 0.12), surfaceColor);

  // ============================================================
  // CONTRASTE AUTOMÁTICO
  // ============================================================

  static Color textoSobreColor(Color fondo) {
    return fondo.computeLuminance() > 0.45 ? Colors.black : Colors.white;
  }

  static Color get textOnPrimary => textoSobreColor(primary);

  static Color get textOnSecondary => textoSobreColor(secondary);

  static Color get textOnAccent => textoSobreColor(accent);

  static Color get textOnIdentity => textoSobreColor(identity);

  static Color get textOnAction => textoSobreColor(action);

  static Color get textOnAccentColor => textoSobreColor(accentColor);

  // ============================================================
  // ALIASES DE COMPATIBILIDAD
  // ============================================================

  static Color get accentGreen => secondary;

  static Color get accentYellow => accent;

  static const Color errorRed = error;

  static const Color destructiveRed = error;

  static Color get primaryBlue => primary;

  // ============================================================
  // COLORES CONSTANTES DE COMPATIBILIDAD
  // ============================================================

  static const Color background = Color(0xFFF7F9FC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceSoft = Color(0xFFF1F5F9);

  static const Color surfaceMutedCompatibility = Color(0xFFE8EDF3);

  static const Color textPrimary = Color(0xFF102033);

  static const Color textSecondary = Color(0xFF526274);

  static const Color textTertiary = Color(0xFF7C8A99);

  static const Color textOnColor = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFD7DEE7);

  static const Color borderSoft = Color(0xFFE8EDF3);

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
      seedColor: identity,
      brightness: Brightness.light,
      primary: identity,
      secondary: action,
      error: error,
      surface: surfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: pageBackground,

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: action,
        selectionColor: actionLight,
        selectionHandleColor: action,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
        ),
        displaySmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: action,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textTertiaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textOnAction,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: action,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: action,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderSoftColor, width: 1),
        ),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: actionLight,
        textColor: textPrimaryColor,
        iconColor: action,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: action,
          foregroundColor: textOnAction,
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
          foregroundColor: action,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: action, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: action,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: action,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: action,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: textTertiaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: TextStyle(color: textTertiaryColor, fontSize: 12),
        errorStyle: const TextStyle(
          color: error,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: action,
        suffixIconColor: action,
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: action, width: 1.5),
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
        side: BorderSide(color: action, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return action;
          }

          return surfaceColor;
        }),
        checkColor: WidgetStateProperty.all(textOnAction),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return action;
          }

          return textTertiaryColor;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return actionLight;
          }

          return surfaceMuted;
        }),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return action;
          }

          return textTertiaryColor;
        }),
      ),

      dividerTheme: DividerThemeData(
        color: borderSoftColor,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: identity,
        contentTextStyle: TextStyle(color: textOnIdentity, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: action,
        headerForegroundColor: textOnAction,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        todayBackgroundColor: WidgetStateProperty.all(actionLight),
        todayForegroundColor: WidgetStateProperty.all(action),
        dayForegroundColor: WidgetStateProperty.all(textPrimaryColor),
        yearForegroundColor: WidgetStateProperty.all(textPrimaryColor),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        modalBarrierColor: const Color(0x33000000),
        elevation: 8,
        showDragHandle: true,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: identity,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: textOnIdentity, fontSize: 12),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: action,
        linearTrackColor: actionLight,
        circularTrackColor: surfaceMuted,
      ),

      iconTheme: IconThemeData(color: action, size: 24),

      tabBarTheme: TabBarThemeData(
        labelColor: action,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: accentColor,
        dividerColor: borderSoftColor,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: action,
        foregroundColor: textOnAction,
        elevation: 2,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: action, width: 1.5),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surfaceColor),
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
        seedColor: identity,
        brightness: Brightness.dark,
        primary: identity,
        secondary: action,
        error: error,
        surface: surfaceColor,
      ),
    );
  }
}
