import 'package:flutter/material.dart';
import '../entities/notification_preferences.dart';

abstract class SettingsRepository {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  double getFontScale();
  Future<void> setFontScale(double scale);

  double getReaderFontScale();
  Future<void> setReaderFontScale(double scale);

  String getReadingMode();
  Future<void> setReadingMode(String mode);

  bool getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);

  NotificationPreferences getNotificationPreferences();
  Future<void> setNotificationPreferences(NotificationPreferences prefs);

  bool getOnboardingSeen();
  Future<void> setOnboardingSeen(bool value);

  /// Borra el progreso de lectura de la Biblia (plan, capitulos leidos,
  /// historial y ultima posicion). Conserva marcadores y favoritos.
  Future<void> resetProgress();
}
