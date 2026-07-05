import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/route_paths.dart';
import '../../providers/settings_providers.dart';

class _OnboardingPage {
  final String image;
  final String title;
  final String description;
  const _OnboardingPage(this.image, this.title, this.description);
}

const _pages = [
  _OnboardingPage(
    'assets/images/maria.jpg',
    'Un momento con Dios cada dia',
    'Lecturas, oraciones y reflexiones que te acompañan sin necesidad de conexion a internet.',
  ),
  _OnboardingPage(
    'assets/images/pastor.jpg',
    'La Biblia en orden',
    'Sigue la Biblia capitulo a capitulo, a tu ritmo. La app recuerda siempre donde quedaste.',
  ),
  _OnboardingPage(
    'assets/images/virgen_orante.jpg',
    'Rosario, oraciones y mas',
    'Un Rosario guiado, una biblioteca de oraciones y tu propio diario espiritual, siempre contigo.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _finish() {
    ref.read(onboardingSeenProvider.notifier).toggle(true);
    context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    // Fondo siempre oscuro con la obra de arte de cada pagina: el texto
    // blanco se lee bien tanto en tema claro como oscuro del telefono.
    return Scaffold(
      backgroundColor: const Color(0xFF120D1C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Image.asset(
              _pages[_index].image,
              key: ValueKey(_index),
              fit: BoxFit.cover,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF120D1C).withValues(alpha: 0.55),
                  const Color(0xFF120D1C).withValues(alpha: 0.35),
                  const Color(0xFF120D1C).withValues(alpha: 0.97),
                ],
                stops: const [0.0, 0.45, 0.85],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text(
                      'Omitir',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final page = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<double>(
                              key: ValueKey(i),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 24 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    page.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    page.description,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.82),
                                          height: 1.5,
                                        ),
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.gold : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF2A1E12),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLast
                          ? _finish
                          : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                      child: Text(
                        isLast ? 'Comenzar' : 'Siguiente',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
