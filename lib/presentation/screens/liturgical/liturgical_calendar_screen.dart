import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/liturgical_calculator.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/art_banner.dart';

class LiturgicalCalendarScreen extends StatelessWidget {
  const LiturgicalCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final info = LiturgicalCalculator.infoFor(today);
    final todayFeast = LiturgicalCalculator.feastFor(today);
    final upcoming = LiturgicalCalculator.upcomingFeasts(today, count: 6);
    final dateFormat = DateFormat('EEEE d \'de\' MMMM \'de\' y', 'es');
    final feastFormat = DateFormat('d \'de\' MMMM', 'es');

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario liturgico')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ArtBanner(
            asset: 'assets/images/natividad.jpg',
            height: 130,
            imageAlignment: Alignment.center,
            child: Text(
              dateFormat.format(today),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text('Color liturgico: ${info.colorName}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Tiempo liturgico: ${info.seasonName}',
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
          if (todayFeast != null) ...[
            const SizedBox(height: 20),
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.celebration_outlined,
                      color: Theme.of(context).colorScheme.secondary, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hoy celebramos', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(todayFeast.name, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Proximas fiestas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...upcoming.map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(f.name, style: Theme.of(context).textTheme.bodyLarge),
                        ),
                        Text(
                          feastFormat.format(f.date),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'El tiempo, el color liturgico y las fiestas moviles (Ceniza, Semana Santa, '
            'Pascua, Pentecostes, Corpus Christi...) se calculan automaticamente cada año. '
            'Ascension y Corpus se muestran en domingo, como se celebran en Colombia.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
