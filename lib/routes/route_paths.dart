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
  static String prayerCategory(String category) => '/prayers/${Uri.encodeComponent(category)}';

  static const rosary = '/rosary';

  static const more = '/more';
  static const favorites = '/more/favorites';
  static const journal = '/more/journal';
  static const music = '/more/music';
  static const liturgicalCalendar = '/more/liturgical-calendar';
  static const saintOfDay = '/more/saint-of-day';
  static const settings = '/more/settings';
}
