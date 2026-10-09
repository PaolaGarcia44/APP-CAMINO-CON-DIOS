import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/bible_local_datasource.dart';
import '../../data/datasources/calendar_local_datasource.dart';
import '../../data/datasources/music_local_datasource.dart';
import '../../data/datasources/prayers_local_datasource.dart';
import '../../data/datasources/quotes_local_datasource.dart';
import '../../data/datasources/reflections_local_datasource.dart';
import '../../data/datasources/saints_local_datasource.dart';

final bibleLocalDataSourceProvider = Provider((ref) => BibleLocalDataSource());
final prayersLocalDataSourceProvider = Provider((ref) => PrayersLocalDataSource());
final quotesLocalDataSourceProvider = Provider((ref) => QuotesLocalDataSource());
final reflectionsLocalDataSourceProvider = Provider((ref) => ReflectionsLocalDataSource());
final saintsLocalDataSourceProvider = Provider((ref) => SaintsLocalDataSource());
final musicLocalDataSourceProvider = Provider((ref) => MusicLocalDataSource());
final calendarLocalDataSourceProvider = Provider((ref) => CalendarLocalDataSource());
