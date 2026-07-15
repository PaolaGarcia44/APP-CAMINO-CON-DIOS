import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/art_banner.dart';
import '../../../core/widgets/faith_icon.dart';
import '../../../domain/usecases/build_rosary_flow.dart';
import '../../providers/content_providers.dart';
import '../../providers/rosary_music_providers.dart';
import '../../providers/settings_providers.dart';

class RosaryScreen extends ConsumerStatefulWidget {
  const RosaryScreen({super.key});

  @override
  ConsumerState<RosaryScreen> createState() => _RosaryScreenState();
}

class _RosaryScreenState extends ConsumerState<RosaryScreen> {
  int _step = 0;
  String? _mysterySetId;

  void _haptic() {
    if (ref.read(vibrationEnabledProvider)) HapticFeedback.mediumImpact();
  }

  void _advance(int totalBeads) {
    if (_step >= totalBeads - 1) return;
    _haptic();
    setState(() => _step += 1);
  }

  void _back() {
    if (_step <= 0) return;
    _haptic();
    setState(() => _step -= 1);
  }

  void _restart() => setState(() => _step = 0);

  void _showMusicSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => const _RosaryMusicSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mysterySetsAsync = ref.watch(rosaryMysterySetsProvider);
    final todaySetAsync = ref.watch(rosaryOfTheDayProvider);
    final prayersAsync = ref.watch(allPrayersProvider);

    final musicState = ref.watch(rosaryMusicProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rosario'),
        actions: [
          IconButton(
            icon: Icon(musicState.isPlaying ? Icons.music_note : Icons.music_note_outlined),
            tooltip: 'Musica de fondo',
            onPressed: () => _showMusicSheet(context),
          ),
          mysterySetsAsync.maybeWhen(
            data: (sets) => PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Cambiar misterios',
              onSelected: (id) => setState(() {
                // "auto" vuelve al misterio que corresponde al dia de hoy.
                _mysterySetId = id == 'auto' ? null : id;
                _step = 0;
              }),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'auto', child: Text('Misterio de hoy (automatico)')),
                const PopupMenuDivider(),
                ...sets.map((s) => PopupMenuItem(value: s.id, child: Text(s.name))),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar',
            onPressed: _restart,
          ),
        ],
      ),
      body: mysterySetsAsync.when(
        data: (sets) => todaySetAsync.when(
          data: (todaySet) => prayersAsync.when(
            data: (prayers) {
              final isAuto = _mysterySetId == null;
              final mysterySet = isAuto
                  ? todaySet
                  : sets.firstWhere((s) => s.id == _mysterySetId, orElse: () => todaySet);
              final beads = BuildRosaryFlow.call(mysterySet: mysterySet, prayers: prayers);
              final index = _step.clamp(0, beads.length - 1);
              final bead = beads[index];

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _advance(beads.length),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Column(
                        children: [
                          ArtBanner(
                            asset: 'assets/images/virgen_orante.jpg',
                            height: 96,
                            imageAlignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  mysterySet.name,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAuto ? 'Misterios de hoy (segun el dia)' : 'Seleccionados manualmente',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: (index + 1) / beads.length, minHeight: 6),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: SingleChildScrollView(
                            key: ValueKey(index),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                FaithIcon(
                                  type: FaithIconType.cross,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  bead.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                if (bead.count != null && bead.total != null) ...[
                                  const SizedBox(height: 6),
                                  _BeadCounter(current: bead.count!, total: bead.total!),
                                ],
                                const SizedBox(height: 20),
                                Text(
                                  bead.text,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _RosaryControls(
                      index: index,
                      total: beads.length,
                      onBack: _back,
                      onNext: () => _advance(beads.length),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('No se pudieron cargar las oraciones.')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Center(child: Text('No se pudo determinar el misterio del dia.')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los misterios.')),
      ),
    );
  }
}

/// Barra inferior con flechas para retroceder / avanzar y el numero de paso.
class _RosaryControls extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _RosaryControls({
    required this.index,
    required this.total,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final atStart = index <= 0;
    final atEnd = index >= total - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  iconSize: 30,
                  onPressed: atStart ? null : onBack,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Anterior',
                ),
                Column(
                  children: [
                    Text(
                      '${index + 1} / $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Paso',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
                IconButton.filled(
                  iconSize: 30,
                  onPressed: atEnd ? null : onNext,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Siguiente',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Toca la pantalla o usa las flechas para avanzar',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior para controlar la musica de fondo del Rosario:
/// reproducir/pausar, elegir el canto y ajustar el volumen.
class _RosaryMusicSheet extends ConsumerWidget {
  const _RosaryMusicSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(rosaryMusicProvider);
    final notifier = ref.read(rosaryMusicProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.music_note, color: primary),
                const SizedBox(width: 8),
                Text('Musica de fondo', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cantos gregorianos para acompañar tu Rosario',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: notifier.toggle,
                  icon: Icon(music.isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(music.isPlaying ? 'Pausar' : 'Reproducir'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    music.track.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: music.volume,
                    onChanged: notifier.setVolume,
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
            const Divider(height: 20),
            for (var i = 0; i < kRosaryTracks.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  i == music.trackIndex ? Icons.play_circle_fill : Icons.play_circle_outline,
                  color: i == music.trackIndex ? primary : null,
                ),
                title: Text(kRosaryTracks[i].title),
                trailing: (i == music.trackIndex && music.isPlaying)
                    ? Icon(Icons.graphic_eq, color: primary)
                    : null,
                onTap: () => notifier.playTrack(i),
              ),
            const SizedBox(height: 4),
            Text(
              'La musica se repite en bucle mientras rezas. Fuente: Gregorian Chant Mass (dominio publico).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BeadCounter extends StatelessWidget {
  final int current;
  final int total;
  const _BeadCounter({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      children: List.generate(total, (i) {
        final active = i < current;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
