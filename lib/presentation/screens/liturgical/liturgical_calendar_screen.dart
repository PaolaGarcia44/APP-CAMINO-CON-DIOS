import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/liturgical_calculator.dart';
import '../../../core/widgets/app_card.dart';

class LiturgicalCalendarScreen extends StatelessWidget {
  const LiturgicalCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final info = LiturgicalCalculator.infoFor(today);
    final dateFormat = DateFormat('EEEE d \'de\' MMMM \'de\' y', 'es');

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario liturgico')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(dateFormat.format(today), style: Theme.of(context).textTheme.bodyLarge),
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
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evangelio del dia', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Disponible proximamente, cuando se integre una fuente con la licencia '
                  'correspondiente para los textos liturgicos oficiales.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'El tiempo y color liturgico se calculan automaticamente a partir de la fecha '
            '(Adviento, Navidad, Cuaresma, Pascua y Tiempo Ordinario). Las fiestas, '
            'solemnidades y memorias se agregaran en una proxima actualizacion.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
