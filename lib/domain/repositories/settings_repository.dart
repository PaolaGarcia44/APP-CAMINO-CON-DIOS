import 'package:flutter/material.dart';

abstract class SettingsRepository {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  double getFontScale();
  Future<void> setFontScale(double scale);

  bool getVibrationEnabled();
  Future<void> setVibrationEnabled(bool value);

  bool getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);

  bool getOnboardingSeen();
  Future<void> setOnboardingSeen(bool value);

  /// Borra el progreso de lectura de la Biblia, marcadores y cache de contenido.
  Future<void> resetProgress();
}
