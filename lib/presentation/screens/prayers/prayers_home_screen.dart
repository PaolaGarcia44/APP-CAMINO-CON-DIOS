import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../routes/route_paths.dart';
import '../../providers/content_providers.dart';

const _categoryIcons = {
  'Basicas': Icons.auto_stories_outlined,
  'Maria': Icons.favorite_border,
  'Proteccion': Icons.shield_outlined,
  'Mañana': Icons.wb_sunny_outlined,
  'Noche': Icons.nightlight_outlined,
  'Antes de dormir': Icons.bedtime_outlined,
  'Antes de trabajar': Icons.work_outline,
  'Antes de estudiar': Icons.school_outlined,
  'Antes de viajar': Icons.flight_outlined,
  'Accion de gracias': Icons.emoji_emotions_outlined,
};

class PrayersHomeScreen extends ConsumerWidget {
  const PrayersHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(prayerCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Oraciones')),
      body: categoriesAsync.when(
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return AppCard(
              onTap: () => context.push(RoutePaths.prayerCategory(category)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[category] ?? Icons.menu_book_outlined,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(category, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar las oraciones.')),
      ),
    );
  }
}
