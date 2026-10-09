class RoutePaths {
  RoutePaths._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';

  static const home = '/home';

  static const bible = '/bible';
  static const bibleBooks = '/bible/books';
  static const bibleSearch = '/bible/search';
  static const bibleBookmarks = '/bible/bookmarks';
  static const bibleHistory = '/bible/history';
  static String bibleChapters(String bookId) => '/bible/books/$bookId';

  /// Lector de un capitulo. Con [verse] el lector se desplaza a ese
  /// versiculo y lo resalta.
  static String bibleRead(String bookId, int chapter, {int? verse}) =>
      '/bible/read/$bookId/$chapter${verse != null ? '?verse=$verse' : ''}';

  static const prayers = '/prayers';
  // Se navega por indice (numerico) para evitar problemas de codificacion en la
  // URL con nombres de categoria que llevan tildes, ñ o espacios (p. ej. "Mañana").
  static String prayerCategory(int index) => '/prayers/$index';

  static const agenda = '/agenda';
  static String agendaNew([DateTime? date]) => date == null
      ? '/agenda/new'
      : '/agenda/new?date=${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String agendaEdit(String id) => '/agenda/edit/$id';

  static const more = '/more';
  static const favorites = '/more/favorites';
  static const journal = '/more/journal';
  static const music = '/more/music';
  static const calendar = '/more/calendar';
  static const reflections = '/more/reflections';
  static const saintOfDay = '/more/saint-of-day';
  static const settings = '/more/settings';
}
