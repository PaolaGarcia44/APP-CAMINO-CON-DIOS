import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/greeting_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/faith_icon.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';
import '../../providers/content_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(todayProvider);
    final progressAsync = ref.watch(bibleProgressProvider);
    final booksAsync = ref.watch(bibleBooksProvider);
    final reflectionAsync = ref.watch(reflectionOfTheDayProvider);
    final prayerAsync = ref.watch(shortPrayerOfDayProvider);
    final quoteAsync = ref.watch(quoteOfTheDayProvider);

    final greeting = GreetingHelper.greetingFor(now);
    final dateLabel = DateFormat("EEEE, d 'de' MMMM", 'es').format(now);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bibleProgressProvider);
          ref.invalidate(reflectionOfTheDayProvider);
          ref.invalidate(shortPrayerOfDayProvider);
          ref.invalidate(quoteOfTheDayProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHero(
                appName: AppConfig.appName,
                tagline: AppConfig.appTagline,
                greeting: greeting,
                dateLabel: dateLabel,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _SectionBlock(
                      title: 'Lectura biblica del dia',
                      child: progressAsync.when(
                        data: (progress) {
                          final bookName = booksAsync.maybeWhen(
                            data: (books) => books
                                .firstWhere(
                                  (book) => book.id == progress.currentBookId,
                                  orElse: () => books.first,
                                )
                                .name,
                            orElse: () => progress.currentBookId,
                          );

                          return AppCard(
                            onTap: () => context.go(
                              RoutePaths.bibleRead(progress.currentBookId, progress.currentChapter),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FeaturedIcon(
                                  icon: Icons.menu_book_rounded,
                                  background: AppColors.blueSoft,
                                  foreground: AppColors.blueDeep,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Día ${progress.dayNumber}',
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$bookName ${progress.currentChapter}',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Continúa la lectura en orden y conserva tu progreso automáticamente.',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          );
                        },
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionBlock(
                      title: 'Accesos rapidos',
                      child: _QuickActionsGrid(),
                    ),
                    const SizedBox(height: 20),
                    _SectionBlock(
                      title: 'Reflexion del dia',
                      child: reflectionAsync.when(
                        data: (reflection) => AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _FeaturedIcon(
                                    icon: Icons.wb_sunny_rounded,
                                    background: AppColors.goldSoft,
                                    foreground: AppColors.gold,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      reflection.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(reflection.text, style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  reflection.closingMessage,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionBlock(
                      title: 'Oracion corta del dia',
                      child: prayerAsync.when(
                        data: (prayer) => AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _FeaturedIcon(
                                    icon: Icons.volunteer_activism_rounded,
                                    background: AppColors.goldSoft,
                                    foreground: AppColors.blueDeep,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      prayer.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(prayer.text, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionBlock(
                      title: 'Frase inspiradora',
                      child: quoteAsync.when(
                        data: (quote) => AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _FeaturedIcon(
                                    icon: Icons.favorite_rounded,
                                    background: AppColors.cream,
                                    foreground: AppColors.gold,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      quote.text,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => Share.share(quote.text),
                                  icon: const Icon(Icons.share_outlined),
                                  label: const Text('Compartir'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const _LoadingCard(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  const _HomeHero({
    required this.appName,
    required this.tagline,
    required this.greeting,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.96),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.92),
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: FaithIcon(
                        type: FaithIconType.cross,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appName, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(tagline, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(greeting, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                dateLabel,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Text(
                  'Lectura, Rosario y oración, siempre disponibles sin conexion.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionItem>[
      _QuickActionItem('Biblia', Icons.menu_book_rounded, AppColors.blueSoft, AppColors.blueDeep, RoutePaths.bible),
      _QuickActionItem('Rosario', Icons.circle_outlined, AppColors.goldSoft, AppColors.gold, RoutePaths.rosary),
      _QuickActionItem('Oraciones', Icons.volunteer_activism_rounded, AppColors.cream, AppColors.blueDeep, RoutePaths.prayers),
      _QuickActionItem('Diario', Icons.edit_note_rounded, AppColors.blueSoft, AppColors.blue, RoutePaths.journal),
      _QuickActionItem('Favoritos', Icons.bookmark_rounded, AppColors.goldSoft, AppColors.gold, RoutePaths.favorites),
      _QuickActionItem('Ajustes', Icons.settings_rounded, AppColors.cream, AppColors.blueDeep, RoutePaths.settings),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions
          .map(
            (action) => SizedBox(
              width: 160,
              child: AppCard(
                onTap: () => context.go(action.route),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: action.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(action.icon, color: action.foreground),
                    ),
                    const SizedBox(height: 14),
                    Text(action.label, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final String route;

  const _QuickActionItem(this.label, this.icon, this.background, this.foreground, this.route);
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
