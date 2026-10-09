import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/liturgical.dart';
import '../../domain/usecases/catholic_calendar.dart';
import 'content_providers.dart';
import 'datasource_providers.dart';

final catholicCalendarProvider = FutureProvider<CatholicCalendar>((ref) async {
  final fixed = await ref.watch(calendarLocalDataSourceProvider).getFixedCelebrations();
  return CatholicCalendar(fixed);
});

/// Informacion liturgica de hoy (para Inicio).
final todayLiturgyProvider = Provider<LiturgicalDay?>((ref) {
  final calendar = ref.watch(catholicCalendarProvider).valueOrNull;
  return calendar?.dayInfo(ref.watch(todayProvider));
});

extension LiturgicalColorUi on LiturgicalColor {
  Color get color => switch (this) {
        LiturgicalColor.blanco => AppColors.gold,
        LiturgicalColor.rojo => const Color(0xFFB3373A),
        LiturgicalColor.verde => const Color(0xFF3F8A5C),
        LiturgicalColor.morado => const Color(0xFF6B4E8E),
        LiturgicalColor.rosa => const Color(0xFFD9839F),
      };
}
