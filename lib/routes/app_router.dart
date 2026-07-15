import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/bible/bible_bookmarks_screen.dart';
import '../presentation/screens/bible/bible_books_screen.dart';
import '../presentation/screens/bible/bible_chapters_screen.dart';
import '../presentation/screens/bible/bible_home_screen.dart';
import '../presentation/screens/bible/bible_reader_screen.dart';
import '../presentation/screens/bible/bible_search_screen.dart';
import '../presentation/screens/favorites/favorites_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/journal/journal_screen.dart';
import '../presentation/screens/liturgical/liturgical_calendar_screen.dart';
import '../presentation/screens/more/more_screen.dart';
import '../presentation/screens/music/music_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/prayers/prayer_category_screen.dart';
import '../presentation/screens/prayers/prayers_home_screen.dart';
import '../presentation/screens/rosary/rosary_screen.dart';
import '../presentation/screens/saint/saint_of_day_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/shell/home_shell.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'route_paths.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RoutePaths.onboarding, builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.bible,
              builder: (context, state) => const BibleHomeScreen(),
              routes: [
                GoRoute(
                  path: 'books',
                  builder: (context, state) => const BibleBooksScreen(),
                  routes: [
                    GoRoute(
                      path: ':bookId',
                      builder: (context, state) =>
                          BibleChaptersScreen(bookId: state.pathParameters['bookId']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'search',
                  builder: (context, state) => const BibleSearchScreen(),
                ),
                GoRoute(
                  path: 'bookmarks',
                  builder: (context, state) => const BibleBookmarksScreen(),
                ),
                GoRoute(
                  path: 'read/:bookId/:chapter',
                  builder: (context, state) => BibleReaderScreen(
                    bookId: state.pathParameters['bookId']!,
                    chapterNumber: int.parse(state.pathParameters['chapter']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.prayers,
              builder: (context, state) => const PrayersHomeScreen(),
              routes: [
                GoRoute(
                  path: ':index',
                  builder: (context, state) => PrayerCategoryScreen(
                    categoryIndex: int.tryParse(state.pathParameters['index'] ?? '') ?? 0,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.rosary, builder: (context, state) => const RosaryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.more,
              builder: (context, state) => const MoreScreen(),
              routes: [
                GoRoute(path: 'favorites', builder: (context, state) => const FavoritesScreen()),
                GoRoute(path: 'journal', builder: (context, state) => const JournalScreen()),
                GoRoute(path: 'music', builder: (context, state) => const MusicScreen()),
                GoRoute(
                  path: 'liturgical-calendar',
                  builder: (context, state) => const LiturgicalCalendarScreen(),
                ),
                GoRoute(path: 'saint-of-day', builder: (context, state) => const SaintOfDayScreen()),
                GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
