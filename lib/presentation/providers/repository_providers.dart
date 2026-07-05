import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/bible_repository_impl.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/repositories/journal_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/bible_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/journal_repository.dart';
import 'datasource_providers.dart';

final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepositoryImpl(dataSource: ref.watch(bibleLocalDataSourceProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl();
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepositoryImpl>((ref) {
  return SettingsRepositoryImpl();
});
