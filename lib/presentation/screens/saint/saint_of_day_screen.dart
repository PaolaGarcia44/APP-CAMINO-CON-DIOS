import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/art_banner.dart';
import '../../providers/content_providers.dart';

class SaintOfDayScreen extends ConsumerWidget {
  const SaintOfDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saintAsync = ref.watch(saintOfTheDayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Santo del dia')),
      body: saintAsync.when(
        data: (saint) {
          if (saint == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el santoral.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final now = DateTime.now();
          final isToday = saint.month == now.month && saint.day == now.day;
          final feastDate = DateFormat("d 'de' MMMM", 'es')
              .format(DateTime(now.year, saint.month, saint.day));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ArtBanner(
                asset: 'assets/images/anunciacion.jpg',
                height: 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saint.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday ? 'Hoy, $feastDate' : 'Fiesta: $feastDate',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Historia', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(saint.story, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frase', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('"${saint.phrase}"',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oracion', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(saint.prayer, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudo cargar el santo del dia.')),
      ),
    );
  }
}
