import '../../data/models/journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> getAll();
  Future<void> add(JournalEntry entry);
  Future<void> update(JournalEntry entry);
  Future<void> delete(String id);

  /// Exporta todas las entradas como una cadena JSON (para respaldo del usuario).
  Future<String> exportAsJson();

  /// Importa entradas desde una cadena JSON previamente exportada.
  Future<void> importFromJson(String jsonString);
}
