import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleBookmarksScreen extends ConsumerWidget {
  const BibleBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bibleBookmarksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Marcadores')),
      body: bookmarksAsync.when(
        data: (keys) {
          if (keys.isEmpty) {
            return const Center(child: Text('Aun no tienes marcadores guardados.'));
          }
          return ListView.separated(
            itemCount: keys.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final parts = keys[i].split(':');
              final bookId = parts[0];
              final chapter = int.parse(parts[1]);
              return ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text('$bookId $chapter'),
                onTap: () => context.push(RoutePaths.bibleRead(bookId, chapter)),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los marcadores.')),
      ),
    );
  }
}
