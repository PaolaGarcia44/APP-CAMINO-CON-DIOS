import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Calendario mensual ligero (sin dependencias externas), con semana de
/// lunes a domingo. Lo usan la Agenda y el Calendario catolico.
///
/// [markersFor] devuelve los colores de los puntos que se dibujan bajo cada
/// dia (p. ej. tareas o celebraciones). Con [compact] solo se muestra la
/// semana del dia seleccionado.
class MonthCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final List<Color> Function(DateTime day)? markersFor;
  final Color? Function(DateTime day)? dayTint;
  final bool compact;

  const MonthCalendar({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onMonthChanged,
    this.markersFor,
    this.dayTint,
    this.compact = false,
  });

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _visibleDays() {
    if (compact) {
      final monday =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day - (selectedDay.weekday - 1));
      return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
    }
    final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final start = DateTime(first.year, first.month, 1 - (first.weekday - 1));
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final cells = ((first.weekday - 1 + daysInMonth) / 7).ceil() * 7;
    return List.generate(cells, (i) => DateTime(start.year, start.month, start.day + i));
  }

  void _shift(int direction) {
    if (compact) {
      final target = DateTime(selectedDay.year, selectedDay.month, selectedDay.day + 7 * direction);
      onDaySelected(target);
      onMonthChanged(DateTime(target.year, target.month));
    } else {
      onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + direction));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = DateTime.now();
    final title = DateFormat('MMMM y', 'es').format(compact ? selectedDay : focusedMonth);
    const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    // Se limita el escalado de texto para que los numeros quepan en las
    // celdas incluso con letra grande en teléfonos pequeños.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: compact ? 'Semana anterior' : 'Mes anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  title[0].toUpperCase() + title.substring(1),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: compact ? 'Semana siguiente' : 'Mes siguiente',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v.abs() > 300) _shift(v < 0 ? 1 : -1);
            },
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              children: [
                for (final day in _visibleDays())
                  _DayCell(
                    day: day,
                    inMonth: compact || day.month == focusedMonth.month,
                    isToday: isSameDay(day, today),
                    isSelected: isSameDay(day, selectedDay),
                    markers: markersFor?.call(day) ?? const [],
                    tint: dayTint?.call(day),
                    onTap: () {
                      onDaySelected(day);
                      if (!compact && day.month != focusedMonth.month) {
                        onMonthChanged(DateTime(day.year, day.month));
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<Color> markers;
  final Color? tint;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.markers,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? scheme.primary
        : isToday
            ? scheme.primaryContainer
            : tint?.withValues(alpha: 0.12);
    final foreground = isSelected
        ? scheme.onPrimary
        : inMonth
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.35);

    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat("d 'de' MMMM", 'es').format(day),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final c in markers.take(3))
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? scheme.onPrimary : c,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
