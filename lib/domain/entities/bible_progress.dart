/// Progreso de lectura secuencial de la Biblia.
class BibleProgress {
  final int dayNumber; // 1-indexado: dia 1 = primer capitulo (Genesis 1)
  final String currentBookId;
  final int currentChapter;
  final DateTime? lastReadDate;

  const BibleProgress({
    required this.dayNumber,
    required this.currentBookId,
    required this.currentChapter,
    this.lastReadDate,
  });
}
