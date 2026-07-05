/// Nombres centralizados de las cajas Hive. Cambiar aqui si se necesita
/// migrar de esquema en el futuro.
class HiveBoxes {
  HiveBoxes._();

  static const String settings = 'settings_box';
  static const String bibleProgress = 'bible_progress_box';
  static const String bibleBookmarks = 'bible_bookmarks_box';
  static const String favorites = 'favorites_box';
  static const String journal = 'journal_box';
  static const String dailyContentCache = 'daily_content_cache_box';
}

/// Claves usadas dentro de la caja de ajustes.
class SettingsKeys {
  SettingsKeys._();

  static const String themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const String fontScale = 'font_scale'; // double
  static const String vibrationEnabled = 'vibration_enabled';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String onboardingSeen = 'onboarding_seen';
}
