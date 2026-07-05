enum JournalCategory { agradecimiento, peticion, reflexion }

extension JournalCategoryX on JournalCategory {
  String get key => toString().split('.').last;

  String get label {
    switch (this) {
      case JournalCategory.agradecimiento:
        return 'Agradecimiento';
      case JournalCategory.peticion:
        return 'Peticion';
      case JournalCategory.reflexion:
        return 'Reflexion personal';
    }
  }

  static JournalCategory fromKey(String key) {
    return JournalCategory.values.firstWhere((e) => e.key == key);
  }
}

class JournalEntry {
  final String id;
  final JournalCategory category;
  final String text;
  final DateTime date;

  const JournalEntry({
    required this.id,
    required this.category,
    required this.text,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category.key,
        'text': text,
        'date': date.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      category: JournalCategoryX.fromKey(map['category'] as String),
      text: map['text'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
