import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/music_model.dart';
import '../../data/models/prayer_model.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/reflection_model.dart';
import '../../data/models/saint_model.dart';
import 'datasource_providers.dart';

final todayProvider = Provider<DateTime>((ref) => DateTime.now());

final prayerCategoriesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(prayersLocalDataSourceProvider).getCategories();
});

final prayersByCategoryProvider = FutureProvider.family<List<PrayerModel>, String>((ref, category) {
  return ref.watch(prayersLocalDataSourceProvider).getByCategory(category);
});

final allPrayersProvider = FutureProvider<List<PrayerModel>>((ref) {
  return ref.watch(prayersLocalDataSourceProvider).getAll();
});

final quoteOfTheDayProvider = FutureProvider<QuoteModel>((ref) {
  return ref.watch(quotesLocalDataSourceProvider).getForDate(ref.watch(todayProvider));
});

final shortPrayerOfDayProvider = FutureProvider<PrayerModel>((ref) {
  return ref.watch(prayersLocalDataSourceProvider).getShortPrayerOfDay(ref.watch(todayProvider));
});

final allReflectionsProvider = FutureProvider<List<ReflectionModel>>((ref) {
  return ref.watch(reflectionsLocalDataSourceProvider).getAll();
});

final reflectionOfTheDayProvider = FutureProvider<ReflectionModel>((ref) {
  return ref.watch(reflectionsLocalDataSourceProvider).getForDate(ref.watch(todayProvider));
});

final saintOfTheDayProvider = FutureProvider<SaintModel?>((ref) {
  return ref.watch(saintsLocalDataSourceProvider).getForDate(ref.watch(todayProvider));
});

final saintsOnDateProvider = FutureProvider.family<List<SaintModel>, DateTime>((ref, date) {
  return ref.watch(saintsLocalDataSourceProvider).getExactlyOn(date);
});

final musicCategoriesProvider = FutureProvider<List<MusicCategoryModel>>((ref) {
  return ref.watch(musicLocalDataSourceProvider).getAll();
});
