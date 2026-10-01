// Colores y tema visual de la app (los mismos de la web Plantamoss).
import 'package:flutter/material.dart';

/// Paleta de colores centralizada. Úsala siempre en lugar de escribir
/// el código hexadecimal en cada pantalla.
class AppColores {
  AppColores._();

  static const verdeOscuro = Color(0xFF2B5E3F); // header y acción principal
  static const verde = Color(0xFF3A7A4F);
  static const verdeIntenso = Color(0xFF2E7D32);
  static const verdeClaro = Color(0xFFA5D6A7);
  static const verdeSuave = Color(0xFFE8F5E9);
  static const fondo = Color(0xFFF7F9F8);
  static const titulo = Color(0xFF1D2B22); // títulos en negro
  static const texto = Color(0xFF66736A); // texto secundario gris
  static const borde = Color(0xFFE5E9E6);
  static const grisChip = Color(0xFFF1F4F2);
  static const rojo = Color(0xFFC62828);
  static const blanco = Colors.white;
}

/// Radios usados en tarjetas y botones.
class AppRadios {
  AppRadios._();
  static const tarjeta = 16.0;
  static const boton = 12.0;
}

/// Construye el tema Material 3 a partir del verde de la marca.
ThemeData construirTema() {
  final esquema =
      ColorScheme.fromSeed(
        seedColor: AppColores.verdeOscuro,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColores.verdeOscuro,
        onPrimary: Colors.white,
        secondary: AppColores.verde,
        surface: Colors.white,
        onSurface: AppColores.titulo,
        error: AppColores.rojo,
        outline: AppColores.borde,
        outlineVariant: AppColores.borde,
      );

  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadios.boton),
    borderSide: const BorderSide(color: AppColores.borde),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: AppColores.fondo,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColores.titulo,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColores.titulo,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColores.titulo,
      ),
      bodyMedium: TextStyle(color: AppColores.titulo),
      bodySmall: TextStyle(color: AppColores.texto),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColores.verdeOscuro,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadios.tarjeta),
        side: const BorderSide(color: AppColores.borde),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: AppColores.verdeOscuro, width: 1.6),
      ),
      labelStyle: const TextStyle(color: AppColores.texto),
      prefixIconColor: AppColores.texto,
      suffixIconColor: AppColores.texto,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColores.verdeOscuro,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadios.boton),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColores.titulo,
        side: const BorderSide(color: AppColores.borde),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadios.boton),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColores.grisChip,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: AppColores.titulo,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerColor: AppColores.borde,
  );
}
