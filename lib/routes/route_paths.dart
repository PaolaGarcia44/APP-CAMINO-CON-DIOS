class RoutePaths {
  RoutePaths._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';

  static const home = '/home';

  static const bible = '/bible';
  static const bibleBooks = '/bible/books';
  static const bibleSearch = '/bible/search';
  static const bibleBookmarks = '/bible/bookmarks';
  static String bibleChapters(String bookId) => '/bible/books/$bookId';
  static String bibleRead(String bookId, int chapter) => '/bible/read/$bookId/$chapter';

  static const prayers = '/prayers';
  // Se navega por indice (numerico) para evitar problemas de codificacion en la
  // URL con nombres de categoria que llevan tildes, ñ o espacios (p. ej. "Mañana").
  static String prayerCategory(int index) => '/prayers/$index';

  static const rosary = '/rosary';

  static const more = '/more';
  static const favorites = '/more/favorites';
  static const journal = '/more/journal';
  static const music = '/more/music';
  static const liturgicalCalendar = '/more/liturgical-calendar';
  static const saintOfDay = '/more/saint-of-day';
  static const settings = '/more/settings';
}
