import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/faith_icon.dart';
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
                  'Aun no tenemos un santo cargado para hoy en esta muestra. '
                  'El santoral completo se agregara en una proxima actualizacion.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: FaithIcon(type: FaithIconType.dove, size: 56, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(saint.name,
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
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
