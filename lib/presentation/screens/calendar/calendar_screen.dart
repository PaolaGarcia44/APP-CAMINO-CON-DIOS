import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/month_calendar.dart';
import '../../../data/models/saint_model.dart';
import '../../../domain/entities/liturgical.dart';
import '../../../domain/usecases/catholic_calendar.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/content_providers.dart';

/// Calendario catolico: tiempo y color liturgico, solemnidades, fiestas,
/// memorias y santos de cada dia. Funciona sin conexion.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _select(DateTime day) => setState(() {
        _selected = DateTime(day.year, day.month, day.day);
        _month = DateTime(day.year, day.month);
      });

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(catholicCalendarProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            tooltip: 'Hoy',
            icon: const Icon(Icons.today_outlined),
            onPressed: () => _select(DateTime.now()),
          ),
        ],
      ),
      body: calendarAsync.when(
        data: (calendar) => _buildBody(context, calendar),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudo cargar el calendario.')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CatholicCalendar calendar) {
    final theme = Theme.of(context);
    final info = calendar.dayInfo(_selected);
    final upcoming = calendar.upcomingSpecial(_selected, count: 6);
    final saints = ref.watch(saintsOnDateProvider(_selected)).valueOrNull ?? const <SaintModel>[];
    final dateLabel = DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(_selected);
    final feastFormat = DateFormat("EEE d 'de' MMM", 'es');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        MonthCalendar(
          focusedMonth: _month,
          selectedDay: _selected,
          onDaySelected: _select,
          onMonthChanged: (m) => setState(() => _month = m),
          markersFor: (day) {
            final principal = calendar.celebrationsOn(day).firstOrNull;
            if (principal == null || principal.rank.weight < LiturgicalRank.memoria.weight) {
              return const [];
            }
            return [principal.color.color];
          },
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel[0].toUpperCase() + dateLabel.substring(1),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(info.weekLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.auto_awesome_outlined, label: info.season.label),
                  _InfoChip(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: info.color.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                      ),
                    ),
                    label: 'Color ${info.color.label.toLowerCase()}',
                  ),
                ],
              ),
              if (info.celebrations.isNotEmpty) ...[
                const Divider(height: 28),
                for (final c in info.celebrations) _CelebrationRow(celebration: c),
              ],
            ],
          ),
        ),
        if (saints.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final saint in saints) _SaintCard(saint: saint),
        ],
        const SizedBox(height: 20),
        Text('Proximas fechas especiales', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final c in upcoming)
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: c.color.color, shape: BoxShape.circle),
                  ),
                  minLeadingWidth: 10,
                  title: Text(c.name),
                  subtitle: Text(c.rank.label),
                  trailing: Text(feastFormat.format(c.date), style: theme.textTheme.labelMedium),
                  onTap: () => _select(c.date),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Calendario Romano General con celebraciones propias de America Latina y Colombia. '
          'Las fechas moviles (Ceniza, Semana Santa, Pascua, Pentecostes...) se calculan cada año. '
          'Epifania, Ascension y Corpus Christi se muestran en domingo, como en Colombia.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;

  const _InfoChip({this.icon, this.leading, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) leading!,
          if (icon != null) Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _CelebrationRow extends StatelessWidget {
  final Celebration celebration;
  const _CelebrationRow({required this.celebration});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              celebration.rank.isSpecial ? Icons.celebration_outlined : Icons.local_florist_outlined,
              size: 20,
              color: celebration.color.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(celebration.name, style: theme.textTheme.titleSmall),
                Text(
                  [
                    celebration.rank.label,
                    if (celebration.region != null) celebration.region!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaintCard extends StatelessWidget {
  final SaintModel saint;
  const _SaintCard({required this.saint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(Icons.emoji_events_outlined, color: theme.colorScheme.secondary),
        title: Text(saint.name, style: theme.textTheme.titleSmall),
        subtitle: Text(saint.phrase, maxLines: 2, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(saint.story),
          const SizedBox(height: 10),
          Text(saint.prayer, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
