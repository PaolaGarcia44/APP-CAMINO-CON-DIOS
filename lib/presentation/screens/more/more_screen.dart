import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../routes/route_paths.dart';

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem(this.icon, this.label, this.route);
}

const _items = [
  _MoreItem(Icons.favorite_outline, 'Favoritos', RoutePaths.favorites),
  _MoreItem(Icons.book_outlined, 'Diario espiritual', RoutePaths.journal),
  _MoreItem(Icons.music_note_outlined, 'Musica catolica', RoutePaths.music),
  _MoreItem(Icons.calendar_month_outlined, 'Calendario liturgico', RoutePaths.liturgicalCalendar),
  _MoreItem(Icons.emoji_events_outlined, 'Santo del dia', RoutePaths.saintOfDay),
  _MoreItem(Icons.settings_outlined, 'Configuracion', RoutePaths.settings),
];

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mas')),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.2,
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return AppCard(
            onTap: () => context.push(item.route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 30, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 10),
                Text(item.label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}
