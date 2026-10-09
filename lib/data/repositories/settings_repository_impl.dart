import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final Box settingsBox;
  final Box progressBox;
  final Box dailyCacheBox;

  SettingsRepositoryImpl({
    Box? settingsBox,
    Box? progressBox,
    Box? dailyCacheBox,
  })  : settingsBox = settingsBox ?? Hive.box(HiveBoxes.settings),
        progressBox = progressBox ?? Hive.box(HiveBoxes.bibleProgress),
        dailyCacheBox = dailyCacheBox ?? Hive.box(HiveBoxes.dailyContentCache);

  @override
  ThemeMode getThemeMode() {
    final raw = settingsBox.get(SettingsKeys.themeMode) as String? ?? 'system';
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await settingsBox.put(SettingsKeys.themeMode, mode.name);
  }

  @override
  double getFontScale() => (settingsBox.get(SettingsKeys.fontScale) as num?)?.toDouble() ?? 1.0;

  @override
  Future<void> setFontScale(double scale) async {
    await settingsBox.put(SettingsKeys.fontScale, scale);
  }

  @override
  double getReaderFontScale() =>
      (settingsBox.get(SettingsKeys.readerFontScale) as num?)?.toDouble() ??
      // Antes la lectura usaba el tamaño general; se respeta como valor inicial.
      getFontScale();

  @override
  Future<void> setReaderFontScale(double scale) async {
    await settingsBox.put(SettingsKeys.readerFontScale, scale);
  }

  @override
  String getReadingMode() => settingsBox.get(SettingsKeys.readingMode) as String? ?? 'standard';

  @override
  Future<void> setReadingMode(String mode) async {
    await settingsBox.put(SettingsKeys.readingMode, mode);
  }

  @override
  bool getNotificationsEnabled() => settingsBox.get(SettingsKeys.notificationsEnabled) as bool? ?? false;

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    await settingsBox.put(SettingsKeys.notificationsEnabled, value);
  }

  @override
  NotificationPreferences getNotificationPreferences() {
    final raw = settingsBox.get(SettingsKeys.notificationPreferences);
    return NotificationPreferences.fromMap(raw is Map ? raw : null, enabled: getNotificationsEnabled());
  }

  @override
  Future<void> setNotificationPreferences(NotificationPreferences prefs) async {
    await settingsBox.put(SettingsKeys.notificationPreferences, prefs.toMap());
    await setNotificationsEnabled(prefs.enabled);
  }

  @override
  bool getOnboardingSeen() => settingsBox.get(SettingsKeys.onboardingSeen) as bool? ?? false;

  @override
  Future<void> setOnboardingSeen(bool value) async {
    await settingsBox.put(SettingsKeys.onboardingSeen, value);
  }

  @override
  Future<void> resetProgress() async {
    // Los marcadores y favoritos se conservan a proposito.
    await progressBox.clear();
    await dailyCacheBox.clear();
  }
}
