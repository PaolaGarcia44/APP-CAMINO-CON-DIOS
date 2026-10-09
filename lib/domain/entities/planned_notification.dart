/// Tipo de aviso; cada uno usa su propio canal de Android.
enum NotificationKind { dailyMessage, reading, reflection, specialDates, agenda }

enum NotificationRepeat { daily, weekly, monthly }

/// Una notificacion lista para programar. [when] es hora local del telefono.
/// Con [repeat] se repite (cada dia, semana o mes) a partir de [when].
class PlannedNotification {
  final int id;
  final String title;
  final String body;
  final DateTime when;
  final NotificationKind kind;
  final NotificationRepeat? repeat;

  /// Ruta de la app que se abre al tocar la notificacion.
  final String? payload;

  const PlannedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.kind,
    this.repeat,
    this.payload,
  });

  @override
  String toString() => 'PlannedNotification($id, $when, $title)';
}
