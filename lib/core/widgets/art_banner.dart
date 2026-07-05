import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Banner decorativo con una obra de arte sacro (dominio publico) y un velo
/// morado para que el texto encima siempre sea legible.
class ArtBanner extends StatelessWidget {
  final String asset;
  final double height;
  final Widget? child;
  final Alignment imageAlignment;
  final BorderRadius borderRadius;

  const ArtBanner({
    super.key,
    required this.asset,
    this.height = 150,
    this.child,
    this.imageAlignment = Alignment.topCenter,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.cover, alignment: imageAlignment),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.purpleDeep.withValues(alpha: 0.20),
                    AppColors.purpleDeep.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(alignment: Alignment.bottomLeft, child: child),
              ),
          ],
        ),
      ),
    );
  }
}
