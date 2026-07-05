import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final Box settingsBox;
  final Box progressBox;
  final Box bookmarksBox;
  final Box dailyCacheBox;

  SettingsRepositoryImpl({
    Box? settingsBox,
    Box? progressBox,
    Box? bookmarksBox,
    Box? dailyCacheBox,
  })  : settingsBox = settingsBox ?? Hive.box(HiveBoxes.settings),
        progressBox = progressBox ?? Hive.box(HiveBoxes.bibleProgress),
        bookmarksBox = bookmarksBox ?? Hive.box(HiveBoxes.bibleBookmarks),
        dailyCacheBox = dailyCacheBox ?? Hive.box(HiveBoxes.dailyContentCache);

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

  Future<void> setThemeMode(ThemeMode mode) async {
    await settingsBox.put(SettingsKeys.themeMode, mode.name);
  }

  double getFontScale() => (settingsBox.get(SettingsKeys.fontScale) as num?)?.toDouble() ?? 1.0;

  Future<void> setFontScale(double scale) async {
    await settingsBox.put(SettingsKeys.fontScale, scale);
  }

  bool getVibrationEnabled() => settingsBox.get(SettingsKeys.vibrationEnabled) as bool? ?? true;

  Future<void> setVibrationEnabled(bool value) async {
    await settingsBox.put(SettingsKeys.vibrationEnabled, value);
  }

  bool getNotificationsEnabled() =>
      settingsBox.get(SettingsKeys.notificationsEnabled) as bool? ?? false;

  Future<void> setNotificationsEnabled(bool value) async {
    await settingsBox.put(SettingsKeys.notificationsEnabled, value);
  }

  bool getOnboardingSeen() => settingsBox.get(SettingsKeys.onboardingSeen) as bool? ?? false;

  Future<void> setOnboardingSeen(bool value) async {
    await settingsBox.put(SettingsKeys.onboardingSeen, value);
  }

  Future<void> resetProgress() async {
    await progressBox.clear();
    await bookmarksBox.clear();
    await dailyCacheBox.clear();
  }
}
