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
  static const String agenda = 'agenda_box';

  /// Todas las cajas que se abren al iniciar la app.
  static const List<String> all = [
    settings,
    bibleProgress,
    bibleBookmarks,
    favorites,
    journal,
    dailyContentCache,
    agenda,
  ];
}

/// Claves usadas dentro de la caja de ajustes.
class SettingsKeys {
  SettingsKeys._();

  static const String themeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const String fontScale = 'font_scale'; // double
  static const String readerFontScale = 'reader_font_scale'; // double
  static const String readingMode = 'reading_mode'; // 'standard' | 'sepia'
  static const String notificationsEnabled = 'notifications_enabled';
  static const String notificationPreferences = 'notification_preferences'; // Map
  static const String onboardingSeen = 'onboarding_seen';
  static const String agendaNotificationCounter = 'agenda_notification_counter';
}
