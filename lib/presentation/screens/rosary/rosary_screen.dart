import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/faith_icon.dart';
import '../../../domain/entities/rosary_bead.dart';
import '../../../domain/usecases/build_rosary_flow.dart';
import '../../providers/content_providers.dart';
import '../../providers/settings_providers.dart';

class RosaryScreen extends ConsumerStatefulWidget {
  const RosaryScreen({super.key});

  @override
  ConsumerState<RosaryScreen> createState() => _RosaryScreenState();
}

class _RosaryScreenState extends ConsumerState<RosaryScreen> {
  int _step = 0;
  String? _mysterySetId;

  void _advance(int totalBeads) {
    final vibration = ref.read(vibrationEnabledProvider);
    if (vibration) HapticFeedback.mediumImpact();
    setState(() {
      _step = (_step + 1) % totalBeads;
    });
  }

  void _restart() => setState(() => _step = 0);

  @override
  Widget build(BuildContext context) {
    final mysterySetsAsync = ref.watch(rosaryMysterySetsProvider);
    final todaySetAsync = ref.watch(rosaryOfTheDayProvider);
    final prayersAsync = ref.watch(allPrayersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rosario'),
        actions: [
          mysterySetsAsync.maybeWhen(
            data: (sets) => PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              onSelected: (id) => setState(() {
                _mysterySetId = id;
                _step = 0;
              }),
              itemBuilder: (context) =>
                  sets.map((s) => PopupMenuItem(value: s.id, child: Text(s.name))).toList(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _restart),
        ],
      ),
      body: mysterySetsAsync.when(
        data: (sets) => todaySetAsync.when(
          data: (todaySet) => prayersAsync.when(
            data: (prayers) {
              final mysterySet = _mysterySetId == null
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
                          Text(mysterySet.name, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: (index + 1) / beads.length, minHeight: 6),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Text(
                        'Toca la pantalla para continuar',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.gold),
                      ),
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
