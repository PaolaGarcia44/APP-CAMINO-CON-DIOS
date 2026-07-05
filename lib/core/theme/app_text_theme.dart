import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografia elegante basada en la fuente del sistema (sin dependencias
/// de red). Para usar una tipografia personalizada en el futuro, agrega los
/// .ttf en assets/fonts, declaralos en pubspec.yaml y cambia `fontFamily`.
class AppTextTheme {
  AppTextTheme._();

  static TextTheme build(Color onSurface) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.25,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.6,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5,
        height: 1.55,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: onSurface,
      ),
    );
  }

  static const TextStyle scripture = TextStyle(
    fontSize: 19,
    height: 1.8,
    letterSpacing: 0.15,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
  );
}
