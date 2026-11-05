import 'package:flutter/material.dart';

/// Design tokens Campus Express — docs/tech.md §3.3 dan PRD §9.2.
class Ce {
  Ce._();

  static const emerald500 = Color(0xFF059669);
  static const emerald600 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);
  static const bg = Color(0xFF04130E);
  static const surface = Color(0xFF0A2219);
  static const surfaceHigh = Color(0xFF0E2E22);
  static const text = Color(0xFFECFDF5);
  static const textMuted = Color(0xFF9CC9B8);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const info = Color(0xFF60A5FA);

  // Token marker peta tracking (Fase 5) — selaras dengan palet web
  // (`apps/web/tailwind.config.ts`): driver hijau brand `#006C4A`,
  // UMKM amber `#D97706`, dan titik tujuan merah `#BA1A1A`.
  static const mapDriver = Color(0xFF006C4A);
  static const mapMerchant = Color(0xFFD97706);
  static const mapDropoff = Color(0xFFBA1A1A);

  static const radiusBento = 20.0;
  static const gap = 12.0;
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Ce.emerald500,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Ce.emerald500,
        secondary: Ce.emerald600,
        surface: Ce.surface,
        onSurface: Ce.text,
        error: Ce.danger,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Ce.bg,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    cardTheme: CardThemeData(
      color: Ce.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ce.radiusBento),
        side: const BorderSide(color: Ce.emerald900, width: 0.6),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Ce.bg,
      foregroundColor: Ce.text,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Ce.surface,
      hintStyle: const TextStyle(color: Ce.textMuted),
      labelStyle: const TextStyle(color: Ce.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Ce.emerald900),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Ce.emerald900),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Ce.emerald500, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Ce.emerald500,
        foregroundColor: Ce.text,
        minimumSize: const Size(44, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Ce.text,
        minimumSize: const Size(44, 48),
        side: const BorderSide(color: Ce.emerald600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Ce.emerald500),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Ce.surfaceHigh,
      selectedColor: Ce.emerald600,
      labelStyle: const TextStyle(color: Ce.text),
      side: const BorderSide(color: Ce.emerald900),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: const DividerThemeData(color: Ce.emerald900, thickness: 0.6),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Ce.surfaceHigh,
      contentTextStyle: const TextStyle(color: Ce.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Ce.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ce.radiusBento),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Ce.surface,
      modalBackgroundColor: Ce.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Ce.surface,
      indicatorColor: Ce.emerald600,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Ce.text, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.all(const IconThemeData(color: Ce.text)),
    ),
    textTheme: base.textTheme.apply(bodyColor: Ce.text, displayColor: Ce.text),
  );
}
