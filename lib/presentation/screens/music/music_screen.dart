import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/music_model.dart';
import '../../providers/content_providers.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  Future<void> _openSearch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(musicCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Musica catolica')),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return _MusicCategoryTile(category: category, onOpen: (uri) => _openSearch(context, uri));
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudo cargar la musica.')),
      ),
    );
  }
}

class _MusicCategoryTile extends StatelessWidget {
  final MusicCategoryModel category;
  final void Function(Uri) onOpen;

  const _MusicCategoryTile({required this.category, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(category.name, style: Theme.of(context).textTheme.titleMedium),
        children: category.songs.map((song) {
          final query = Uri.encodeComponent(song.searchTerm);
          return ListTile(
            title: Text(song.title),
            subtitle: Text(song.artist),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Buscar en YouTube',
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () =>
                      onOpen(Uri.parse('https://www.youtube.com/results?search_query=$query')),
                ),
                IconButton(
                  tooltip: 'Buscar en Spotify',
                  icon: const Icon(Icons.library_music_outlined),
                  onPressed: () => onOpen(Uri.parse('https://open.spotify.com/search/$query')),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
