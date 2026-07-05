import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';

/// Tarjeta artistica para la frase del dia: obra de arte de fondo, frase
/// encima y opcion de compartirla como imagen (novedad de la version 0.3).
class QuoteArtCard extends StatefulWidget {
  final String quoteText;
  final String appName;

  const QuoteArtCard({super.key, required this.quoteText, required this.appName});

  @override
  State<QuoteArtCard> createState() => _QuoteArtCardState();
}

class _QuoteArtCardState extends State<QuoteArtCard> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareAsImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/frase_del_dia.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: widget.quoteText,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar la imagen.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/images/anunciacion.jpg', fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.purpleDeep.withValues(alpha: 0.45),
                          AppColors.purpleDeep.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded,
                          color: AppColors.goldSoft, size: 34),
                      const SizedBox(height: 10),
                      Text(
                        widget.quoteText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 2,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.appName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.goldSoft,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => Share.share(widget.quoteText),
              icon: const Icon(Icons.notes_rounded, size: 18),
              label: const Text('Compartir texto'),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: _sharing ? null : _shareAsImage,
              icon: _sharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.image_outlined, size: 18),
              label: const Text('Compartir imagen'),
            ),
          ],
        ),
      ],
    );
  }
}
