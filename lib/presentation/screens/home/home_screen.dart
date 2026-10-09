import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/greeting_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/faith_icon.dart';
import '../../../core/widgets/quote_art_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/favorite_item.dart';
import '../../../domain/entities/liturgical.dart';
import '../../../routes/route_paths.dart';
import '../../providers/agenda_providers.dart';
import '../../providers/bible_providers.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/content_providers.dart';
import '../../providers/favorites_providers.dart';
import '../agenda/task_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final liturgy = ref.watch(todayLiturgyProvider);
    final quoteAsync = ref.watch(quoteOfTheDayProvider);
    final reflectionAsync = ref.watch(reflectionOfTheDayProvider);
    final upcoming = ref.watch(upcomingTasksProvider);
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? const <FavoriteItem>[];

    final greeting = GreetingHelper.greetingFor(now);
    final dateLabel = DateFormat("EEEE, d 'de' MMMM", 'es').format(now);
    final special = liturgy?.special;
    var delay = 0;
    int nextDelay() => (delay += 80);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayProvider);
          ref.invalidate(bibleProgressProvider);
          ref.invalidate(lastReadingPositionProvider);
          ref.invalidate(upcomingTasksProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHero(
                appName: AppConfig.appName,
                tagline: AppConfig.appTagline,
                greeting: greeting,
                dateLabel: dateLabel[0].toUpperCase() + dateLabel.substring(1),
                liturgy: liturgy,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (special != null) ...[
                    FadeSlideIn(
                      delayMs: 0,
                      child: _SpecialDateCard(
                        celebration: special,
                        onTap: () => context.push(RoutePaths.calendar),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _SectionBlock(
                    title: 'Mensaje del día',
                    delayMs: nextDelay(),
                    child: quoteAsync.when(
                      data: (quote) {
                        final favoriteId = 'quote:${quote.id}';
                        final isFavorite = favorites.any((f) => f.id == favoriteId);
                        return QuoteArtCard(
                          quoteText: quote.text,
                          reference: quote.reference,
                          appName: AppConfig.appName,
                          isFavorite: isFavorite,
                          onToggleFavorite: () {
                            final notifier = ref.read(favoritesProvider.notifier);
                            if (isFavorite) {
                              notifier.remove(favoriteId);
                            } else {
                              notifier.add(FavoriteItem(
                                id: favoriteId,
                                type: FavoriteType.quote,
                                title: quote.reference ?? 'Mensaje del día',
                                content: quote.text,
                                dateAdded: DateTime.now(),
                              ));
                            }
                          },
                        );
                      },
                      loading: () => const _LoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionBlock(
                    title: 'Tu lectura bíblica',
                    delayMs: nextDelay(),
                    child: const _ReadingCard(),
                  ),
                  const SizedBox(height: 22),
                  _SectionBlock(
                    title: 'Próximas tareas',
                    actionLabel: 'Ver agenda',
                    onAction: () => context.go(RoutePaths.agenda),
                    delayMs: nextDelay(),
                    child: upcoming.isEmpty
                        ? AppCard(
                            onTap: () => context.push(RoutePaths.agendaNew()),
                            child: Row(
                              children: [
                                const _FeaturedIcon(
                                  icon: Icons.event_available_rounded,
                                  background: AppColors.purpleSoft,
                                  foreground: AppColors.purpleDeep,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'No tienes tareas próximas. Toca para crear una.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const Icon(Icons.add_rounded),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (final o in upcoming)
                                TaskTile(occurrence: o, dense: true, key: ValueKey('${o.task.id}${o.at}')),
                            ],
                          ),
                  ),
                  const SizedBox(height: 22),
                  _SectionBlock(
                    title: 'Reflexión del día',
                    delayMs: nextDelay(),
                    child: reflectionAsync.when(
                      data: (reflection) => AppCard(
                        onTap: () => context.push(RoutePaths.reflections),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _FeaturedIcon(
                                  icon: Icons.wb_sunny_rounded,
                                  background: AppColors.goldSoft,
                                  foreground: AppColors.gold,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reflection.title, style: Theme.of(context).textTheme.titleMedium),
                                      Text(reflection.verseRef, style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reflection.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Leer reflexión',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const _LoadingCard(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Continuar donde quedo el usuario; si nunca ha leido, el plan del dia.
class _ReadingCard extends ConsumerWidget {
  const _ReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastPosition = ref.watch(lastReadingPositionProvider);
    final progress = ref.watch(bibleProgressProvider).valueOrNull;
    final booksById = ref.watch(bibleBooksByIdProvider);
    final readCount = ref.watch(readChaptersProvider).length;
    final total = ref.watch(bibleTotalChaptersProvider).valueOrNull ?? 0;
    final theme = Theme.of(context);

    String name(String id) => booksById[id]?.name ?? id;

    final String title;
    final String subtitle;
    final String route;
    if (lastPosition != null) {
      title = '${name(lastPosition.bookId)} ${lastPosition.chapter}'
          '${lastPosition.verse != null ? ':${lastPosition.verse}' : ''}';
      subtitle = 'Continúa donde lo dejaste';
      route = RoutePaths.bibleRead(lastPosition.bookId, lastPosition.chapter, verse: lastPosition.verse);
    } else if (progress != null) {
      title = '${name(progress.currentBookId)} ${progress.currentChapter}';
      subtitle = 'Comienza la Biblia en orden, capítulo a capítulo';
      route = RoutePaths.bibleRead(progress.currentBookId, progress.currentChapter);
    } else {
      return const _LoadingCard();
    }

    return AppCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _FeaturedIcon(
                icon: Icons.menu_book_rounded,
                background: AppColors.purpleSoft,
                foreground: AppColors.purpleDeep,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(title, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          if (total > 0 && readCount > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: readCount / total, minHeight: 6),
            ),
            const SizedBox(height: 6),
            Text('$readCount de $total capítulos leídos', style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _SpecialDateCard extends StatelessWidget {
  final Celebration celebration;
  final VoidCallback onTap;

  const _SpecialDateCard({required this.celebration, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.95),
                const Color(0xFFB08436),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoy celebramos · ${celebration.rank.label}',
                      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      celebration.name,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  final String appName;
  final String tagline;
  final String greeting;
  final String dateLabel;
  final LiturgicalDay? liturgy;

  const _HomeHero({
    required this.appName,
    required this.tagline,
    required this.greeting,
    required this.dateLabel,
    required this.liturgy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liturgy = this.liturgy;
    // Las memorias (no "fechas especiales") se mencionan aqui sin otra tarjeta.
    final memorial = liturgy?.special == null ? liturgy?.principal : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/maria.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.purpleDeep.withValues(alpha: 0.92),
              theme.colorScheme.primary.withValues(alpha: 0.70),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: FaithIcon(type: FaithIconType.cross, size: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appName, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(tagline, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(greeting, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                if (liturgy != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: liturgy.color.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liturgy.weekLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                              ),
                              if (memorial != null)
                                Text(
                                  memorial.name,
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;
  final int delayMs;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionBlock({
    required this.title,
    required this.child,
    this.delayMs = 0,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delayMs: delayMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, actionLabel: actionLabel, onAction: onAction),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FeaturedIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _FeaturedIcon({required this.icon, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: foreground, size: 24),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
