import 'dart:convert';
import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../domain/repositories/journal_repository.dart';
import '../models/journal_entry.dart';

class JournalRepositoryImpl implements JournalRepository {
  final Box box;

  JournalRepositoryImpl({Box? box}) : box = box ?? Hive.box(HiveBoxes.journal);

  @override
  Future<List<JournalEntry>> getAll() async {
    final items = box.values
        .map((e) => JournalEntry.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Future<void> add(JournalEntry entry) async {
    await box.put(entry.id, entry.toMap());
  }

  @override
  Future<void> update(JournalEntry entry) async {
    await box.put(entry.id, entry.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await box.delete(id);
  }

  @override
  Future<String> exportAsJson() async {
    final entries = await getAll();
    return json.encode(entries.map((e) => e.toMap()).toList());
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    final list = json.decode(jsonString) as List;
    for (final raw in list) {
      final entry = JournalEntry.fromMap(raw as Map<String, dynamic>);
      await box.put(entry.id, entry.toMap());
    }
  }
}
