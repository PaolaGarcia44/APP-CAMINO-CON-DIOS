import 'package:flutter/material.dart';

/// Paleta de la app: morado, dorado y blanco calido.
/// Mantener todos los colores aqui para que el tema sea facil de ajustar.
class AppColors {
  AppColors._();

  // Marca
  static const Color purple = Color(0xFF6A4C93);
  static const Color purpleDeep = Color(0xFF412A66);
  static const Color purpleSoft = Color(0xFFEBE3F7);
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldSoft = Color(0xFFF2E4C2);
  static const Color cream = Color(0xFFFAF7FD);
  static const Color warmWhite = Color(0xFFFFFEFD);

  // Neutros
  static const Color inkLight = Color(0xFF272430);
  static const Color inkDark = Color(0xFFEFEAF5);

  // Superficies modo oscuro
  static const Color surfaceDark = Color(0xFF171221);
  static const Color surfaceDarkAlt = Color(0xFF221A31);
  static const Color purpleDarkAccent = Color(0xFFB79CE4);
  static const Color goldDarkAccent = Color(0xFFDCC07E);

  // Estados
  static const Color success = Color(0xFF4C8B6B);
  static const Color error = Color(0xFFB3554A);
}
